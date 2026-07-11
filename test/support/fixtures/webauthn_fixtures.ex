defmodule App.WebauthnFixtures do
  @moduledoc """
  This module defines test helpers for faking WebAuthn authenticator
  responses, since the `wax_` library ships no test fixtures of its own.

  Only the `"none"` attestation format is supported (no signature to
  produce), which matches what `App.Accounts.Webauthn` requests.
  """

  @doc """
  Builds a fake `"none"`-attestation registration response for the given
  `Wax.Challenge`, shaped like what `@simplewebauthn/browser`'s
  `startRegistration/1` resolves to.
  """
  @spec fake_registration_response(Wax.Challenge.t(), keyword()) :: map()
  def fake_registration_response(%Wax.Challenge{} = challenge, opts \\ []) do
    credential_id = Keyword.get(opts, :credential_id, :crypto.strong_rand_bytes(16))
    aaguid = Keyword.get(opts, :aaguid, <<0::128>>)
    user_present = Keyword.get(opts, :user_present, true)
    user_verified = Keyword.get(opts, :user_verified, true)

    auth_data =
      build_authenticator_data(challenge, credential_id, aaguid, user_present, user_verified)

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

  defp build_authenticator_data(challenge, credential_id, aaguid, user_present, user_verified) do
    rp_id_hash = :crypto.hash(:sha256, challenge.rp_id)

    flags =
      <<0::1, 1::1, 0::1, 0::1, 0::1, bool_bit(user_verified)::1, 0::1,
        bool_bit(user_present)::1>>

    sign_count = <<0::unsigned-big-integer-size(32)>>

    cose_key = fake_cose_key()

    attested_credential_data =
      aaguid <>
        <<byte_size(credential_id)::unsigned-big-integer-size(16)>> <>
        credential_id <>
        CBOR.encode(cose_key)

    rp_id_hash <> flags <> sign_count <> attested_credential_data
  end

  defp fake_cose_key do
    {public_key, _private_key} = :crypto.generate_key(:ecdh, :secp256r1)
    <<4, x::binary-size(32), y::binary-size(32)>> = public_key

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
