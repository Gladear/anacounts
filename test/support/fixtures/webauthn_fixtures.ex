defmodule App.WebauthnFixtures do
  @moduledoc """
  This module defines test helpers for faking WebAuthn authenticator
  responses, since the `wax_` library ships no test fixtures of its own.

  Only the `"none"` attestation format is supported (no signature to
  produce), which matches what `App.Accounts.Webauthn` requests.
  """

  @doc """
  Generates a fake authenticator ES256 keypair, as returned by
  `:crypto.generate_key/2`: `{public_key, private_key}`.
  """
  @spec generate_keypair() :: {binary(), binary()}
  def generate_keypair, do: :crypto.generate_key(:ecdh, :secp256r1)

  @doc """
  Builds a fake `"none"`-attestation registration response for the given
  `Wax.Challenge`, shaped like what `@simplewebauthn/browser`'s
  `startRegistration/1` resolves to.

  Accepts a `:keypair` (as returned by `generate_keypair/0`) so the same key
  material can later be used to sign a matching `fake_authentication_response/2`.
  """
  @spec fake_registration_response(Wax.Challenge.t(), keyword()) :: map()
  def fake_registration_response(%Wax.Challenge{} = challenge, opts \\ []) do
    credential_id = Keyword.get(opts, :credential_id, :crypto.strong_rand_bytes(16))
    aaguid = Keyword.get(opts, :aaguid, <<0::128>>)
    user_present = Keyword.get(opts, :user_present, true)
    user_verified = Keyword.get(opts, :user_verified, true)
    {public_key, _private_key} = Keyword.get(opts, :keypair, generate_keypair())

    auth_data =
      build_registration_authenticator_data(
        challenge,
        credential_id,
        aaguid,
        user_present,
        user_verified,
        public_key
      )

    attestation_object =
      CBOR.encode(%{"fmt" => "none", "attStmt" => %{}, "authData" => auth_data})

    client_data_json =
      JSON.encode!(%{
        "type" => "webauthn.create",
        "challenge" => Base.url_encode64(challenge.bytes, padding: false),
        "origin" => challenge.origin
      })

    %{
      "id" => Base.url_encode64(credential_id, padding: false),
      "rawId" => Base.url_encode64(credential_id, padding: false),
      "type" => "public-key",
      "response" => %{
        "attestationObject" => Base.url_encode64(attestation_object, padding: false),
        "clientDataJSON" => Base.url_encode64(client_data_json, padding: false)
      }
    }
  end

  @doc """
  Builds a fake authentication (assertion) response for the given
  `Wax.Challenge`, shaped like what `@simplewebauthn/browser`'s
  `startAuthentication/1` resolves to.

  Requires the `:credential_id` and `:keypair` used to build the matching
  `fake_registration_response/2`, so the assertion signature verifies against
  the stored public key.
  """
  @spec fake_authentication_response(Wax.Challenge.t(), keyword()) :: map()
  def fake_authentication_response(%Wax.Challenge{} = challenge, opts) do
    credential_id = Keyword.fetch!(opts, :credential_id)
    {_public_key, private_key} = Keyword.fetch!(opts, :keypair)
    sign_count = Keyword.get(opts, :sign_count, 1)
    user_present = Keyword.get(opts, :user_present, true)
    user_verified = Keyword.get(opts, :user_verified, true)

    auth_data =
      build_authentication_authenticator_data(challenge, sign_count, user_present, user_verified)

    client_data_json =
      JSON.encode!(%{
        "type" => "webauthn.get",
        "challenge" => Base.url_encode64(challenge.bytes, padding: false),
        "origin" => challenge.origin
      })

    client_data_hash = :crypto.hash(:sha256, client_data_json)

    signature =
      :crypto.sign(:ecdsa, :sha256, auth_data <> client_data_hash, [private_key, :secp256r1])

    %{
      "id" => Base.url_encode64(credential_id, padding: false),
      "rawId" => Base.url_encode64(credential_id, padding: false),
      "type" => "public-key",
      "response" => %{
        "authenticatorData" => Base.url_encode64(auth_data, padding: false),
        "signature" => Base.url_encode64(signature, padding: false),
        "clientDataJSON" => Base.url_encode64(client_data_json, padding: false)
      }
    }
  end

  defp build_registration_authenticator_data(
         challenge,
         credential_id,
         aaguid,
         user_present,
         user_verified,
         public_key
       ) do
    rp_id_hash = :crypto.hash(:sha256, challenge.rp_id)
    flags = flags_byte(user_present, user_verified, true)
    sign_count = <<0::unsigned-big-integer-size(32)>>

    cose_key = cose_key_from_public_key(public_key)

    attested_credential_data =
      aaguid <>
        <<byte_size(credential_id)::unsigned-big-integer-size(16)>> <>
        credential_id <>
        CBOR.encode(cose_key)

    rp_id_hash <> flags <> sign_count <> attested_credential_data
  end

  defp build_authentication_authenticator_data(challenge, sign_count, user_present, user_verified) do
    rp_id_hash = :crypto.hash(:sha256, challenge.rp_id)
    flags = flags_byte(user_present, user_verified, false)
    sign_count = <<sign_count::unsigned-big-integer-size(32)>>

    rp_id_hash <> flags <> sign_count
  end

  defp flags_byte(user_present, user_verified, attested_credential_data) do
    <<0::1, bool_bit(attested_credential_data)::1, 0::1, 0::1, 0::1, bool_bit(user_verified)::1,
      0::1, bool_bit(user_present)::1>>
  end

  @doc """
  Converts a raw ES256 public key (as returned by `generate_keypair/0`) into
  the decoded COSE key map format `App.Accounts.Webauthn` stores (via
  `:erlang.term_to_binary/1`) alongside a passkey.
  """
  @spec cose_key_from_public_key(binary()) :: map()
  def cose_key_from_public_key(<<4, x::binary-size(32), y::binary-size(32)>>) do
    %{
      # kty: EC2
      1 => 2,
      # alg: ES256
      3 => -7,
      # crv: P-256
      -1 => 1,
      -2 => x,
      -3 => y
    }
  end

  defp bool_bit(true), do: 1
  defp bool_bit(false), do: 0
end
