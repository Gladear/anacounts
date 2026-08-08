defmodule App.Accounts.Webauthn do
  @moduledoc """
  See https://webauthn.guide for a more detailed explanation.
  """

  import Ecto.Query

  alias App.Accounts
  alias App.Accounts.User
  alias App.Accounts.UserPasskey
  alias App.Repo

  ## Passkey authentication

  @doc """
  Generates a WebAuthn authentication challenge and the corresponding
  PublicKeyCredentialRequestOptions to send to the browser.
  """
  @spec begin_passkey_authentication() :: {Wax.Challenge.t(), map()}
  def begin_passkey_authentication do
    challenge =
      Wax.new_authentication_challenge(
        allow_credentials: [],
        origin: webauthn_origin(),
        rp_id: webauthn_rp_id(),
        # Require the authenticator to verify the user (PIN, biometrics...),
        # not just confirm their presence, since a passkey is meant to be a
        # standalone authentication factor, not a second one.
        user_verification: "required"
      )

    options = %{
      "challenge" => Base.url_encode64(challenge.bytes, padding: false),
      "rpId" => webauthn_rp_id(),
      "allowCredentials" => [],
      "userVerification" => challenge.user_verification,
      "timeout" => challenge.timeout * 1_000
    }

    {challenge, options}
  end

  @doc """
  Verifies a WebAuthn assertion, and returns the related user on success.
  """
  @spec verify_passkey_authentication(map(), Wax.Challenge.t()) ::
          {:ok, User.t()}
          | {:error, :invalid_credential}
          | {:error, :not_found}
          | {:error, :cloned_authenticator}
          | {:error, {:wax, Exception.t()}}
  def verify_passkey_authentication(credential_response, stored_challenge) do
    Repo.transact(fn ->
      with {:ok, credential_id, passkey, challenge} <-
             resolve_asserted_credential(credential_response, stored_challenge),
           {:ok, authenticator_data} <-
             authenticate(credential_id, credential_response, challenge),
           :ok <- verify_sign_count(passkey, authenticator_data.sign_count) do
        record_sign_count(passkey, authenticator_data.sign_count)
        {:ok, Accounts.get_user!(passkey.user_id)}
      else
        :error -> {:error, :invalid_credential}
        {:error, _} = error -> error
      end
    end)
  end

  # Looks up the passkey the client claims to be asserting, and restricts the
  # challenge to that single credential's public key so `Wax.authenticate/6`
  # verifies the signature against it.
  defp resolve_asserted_credential(credential_response, stored_challenge) do
    with {:ok, credential_id} <-
           Base.url_decode64(credential_response["rawId"], padding: false),
         {:ok, passkey} <- fetch_passkey_by_credential_id(credential_id) do
      cose_key = :erlang.binary_to_term(passkey.public_key, [:safe])
      challenge = %{stored_challenge | allow_credentials: [{credential_id, cose_key}]}
      {:ok, credential_id, passkey, challenge}
    end
  end

  defp fetch_passkey_by_credential_id(credential_id) do
    query =
      from user_passkey in UserPasskey.base_query(),
        where: user_passkey.credential_id == ^credential_id,
        lock: "FOR UPDATE"

    if passkey = Repo.one(query) do
      {:ok, passkey}
    else
      {:error, :not_found}
    end
  end

  defp authenticate(credential_id, credential_response, challenge) do
    response = credential_response["response"]

    with {:ok, auth_data} <- Base.url_decode64(response["authenticatorData"], padding: false),
         {:ok, sig} <- Base.url_decode64(response["signature"], padding: false),
         {:ok, client_data_json} <- Base.url_decode64(response["clientDataJSON"], padding: false) do
      wax_authenticate(credential_id, auth_data, sig, client_data_json, challenge)
    end
  end

  defp wax_authenticate(credential_id, auth_data, sig, client_data_json, challenge) do
    with {:error, reason} <-
           Wax.authenticate(credential_id, auth_data, sig, client_data_json, challenge) do
      {:error, {:wax, reason}}
    end
  end

  # Per WebAuthn 7.2 step 17: a sign count that doesn't strictly increase
  # indicates the authenticator's private key may have been cloned. Some
  # platform authenticators (e.g. Touch ID) never implement a counter and
  # always report 0, so the check is skipped when either side is 0.
  defp verify_sign_count(%UserPasskey{} = passkey, new_count) when is_integer(new_count) do
    stored_count = passkey.sign_count

    cond do
      stored_count == 0 or new_count == 0 -> :ok
      stored_count < new_count -> :ok
      true -> {:error, :cloned_authenticator}
    end
  end

  defp record_sign_count(passkey, sign_count) do
    passkey
    |> UserPasskey.change_sign_count_changeset(sign_count)
    |> Repo.update!()
  end

  ## Passkey creation (settings)

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
