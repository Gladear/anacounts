defmodule App.Accounts.Webauthn do
  @moduledoc """
  See https://webauthn.guide for a more detailed explanation.
  """

  alias App.Accounts
  alias App.Accounts.User
  alias App.Accounts.UserPasskey
  alias App.Repo

  @doc """
  Generates a WebAuthn registration challenge and the corresponding
  PublicKeyCredentialCreationOptions to send to the browser.
  """
  @spec begin_passkey_registration(User.t()) :: {Wax.Challenge.t(), map()}
  def begin_passkey_registration(%User{} = user) do
    challenge =
      Wax.new_registration_challenge(
        origin: webauthn_origin(),
        rp_id: webauthn_rp_id(),
        # Accept attestation statements signed either by the authenticator's
        # own batch certificate ("basic") or with no attestation at all
        # ("none"). We don't check attestation against FIDO metadata, so
        # anything beyond this wouldn't buy us more trust.
        trusted_attestation_types: [:none, :basic],
        # Don't collect attestation: we don't verify it against FIDO metadata,
        # so requesting it would only add friction (and a privacy-sensitive
        # prompt) without any security benefit.
        attestation: "none",
        # Require the authenticator to verify the user (PIN, biometrics...),
        # not just confirm their presence, since a passkey is meant to be a
        # standalone authentication factor.
        user_verification: "required"
      )

    options = %{
      "challenge" => Base.url_encode64(challenge.bytes, padding: false),
      "rp" => %{"name" => webauthn_rp_name(), "id" => webauthn_rp_id()},
      "user" => %{
        "id" => Base.url_encode64(<<user.id::64>>, padding: false),
        # Shown by the browser/authenticator UI. This should be used to help
        # the user tell accounts apart, but we don't have any user information.
        "name" => "user",
        "displayName" => "User"
      },
      "pubKeyCredParams" => [
        # ES256, preferred: cheaper to compute and verify than RS256
        %{"type" => "public-key", "alg" => -7},
        # RS256, fallback for authenticators that don't support ES256
        %{"type" => "public-key", "alg" => -257}
      ],
      "timeout" => challenge.timeout * 1_000,
      "attestation" => challenge.attestation,
      "authenticatorSelection" => %{
        # Require a discoverable (resident) credential, so the authenticator
        # can list the user's accounts by itself during sign-in, without the
        # server having to send `allowCredentials` first.
        "residentKey" => "required",
        "requireResidentKey" => true,
        "userVerification" => challenge.user_verification
      },
      # Prevent registering the same authenticator twice for this user.
      "excludeCredentials" =>
        for passkey <- Accounts.list_user_passkeys(user) do
          %{
            "id" => Base.url_encode64(passkey.credential_id, padding: false),
            "type" => "public-key"
          }
        end
    }

    {challenge, options}
  end

  @doc """
  Verifies a WebAuthn attestation response and returns a built, non persisted passkey
  for the given user.
  """
  @spec verify_passkey_registration(User.t(), map(), Wax.Challenge.t()) ::
          {:ok, UserPasskey.built_t()} | {:error, term()}
  def verify_passkey_registration(%User{} = user, credential_response, challenge) do
    with {:ok, attestation_obj} <-
           Base.url_decode64(credential_response["response"]["attestationObject"], padding: false),
         {:ok, client_data_json} <-
           Base.url_decode64(credential_response["response"]["clientDataJSON"], padding: false),
         {:ok, {auth_data, _}} <- Wax.register(attestation_obj, client_data_json, challenge) do
      {:ok, user_auth_data_passkey(user, auth_data)}
    end
  end

  @doc """
  Register a passkey for a user. The passkey is not verified.
  """
  @spec register_passkey(UserPasskey.t(), map()) ::
          {:ok, UserPasskey.t()} | {:error, Ecto.Changeset.t()}
  def register_passkey(%UserPasskey{} = user_passkey, user_passkey_attrs) do
    user_passkey
    |> UserPasskey.device_name_changeset(user_passkey_attrs)
    |> Repo.insert()
  end

  @spec user_auth_data_passkey(User.t(), Wax.AuthenticatorData.t()) :: UserPasskey.built_t()
  defp user_auth_data_passkey(%User{} = user, auth_data) do
    %UserPasskey{
      user_id: user.id,
      credential_id: auth_data.attested_credential_data.credential_id,
      public_key:
        :erlang.term_to_binary(auth_data.attested_credential_data.credential_public_key),
      aaguid: Wax.AuthenticatorData.get_aaguid(auth_data),
      sign_count: auth_data.sign_count
    }
  end

  defp webauthn_origin, do: webauthn_config!(:origin)
  defp webauthn_rp_id, do: webauthn_config!(:rp_id)
  defp webauthn_rp_name, do: webauthn_config!(:rp_name)

  defp webauthn_config!(key) do
    Application.fetch_env!(:app, __MODULE__)
    |> Keyword.fetch!(key)
  end
end
