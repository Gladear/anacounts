defmodule App.Accounts.WebauthnTest do
  use App.DataCase, async: true

  import App.AccountsFixtures
  import App.WebauthnFixtures

  alias App.Accounts.UserPasskey
  alias App.Accounts.Webauthn

  setup do
    %{user: user_fixture()}
  end

  describe "begin_passkey_registration/1" do
    test "returns a challenge and matching PublicKeyCredentialCreationOptions", %{user: user} do
      {challenge, options} = Webauthn.begin_passkey_registration(user)

      assert %Wax.Challenge{type: :attestation} = challenge
      assert options["challenge"] == Base.url_encode64(challenge.bytes, padding: false)
      assert options["rp"] == %{"name" => "Anacounts", "id" => challenge.rp_id}
      assert options["user"]["id"] == Base.url_encode64(<<user.id::64>>, padding: false)

      assert options["pubKeyCredParams"] == [
               %{"type" => "public-key", "alg" => -7},
               %{"type" => "public-key", "alg" => -257}
             ]

      assert options["authenticatorSelection"]["userVerification"] == "required"
    end

    test "requires user verification, matching the challenge it generates", %{user: user} do
      {challenge, _options} = Webauthn.begin_passkey_registration(user)

      assert challenge.user_verification == "required"
    end

    test "sets the options' timeout and attestation from the challenge", %{user: user} do
      {challenge, options} = Webauthn.begin_passkey_registration(user)

      assert options["timeout"] == challenge.timeout * 1_000
      assert options["attestation"] == challenge.attestation
    end

    test "excludes the user's existing passkeys from registration", %{user: user} do
      passkey = user_passkey_fixture(user)

      {_challenge, options} = Webauthn.begin_passkey_registration(user)

      assert options["excludeCredentials"] == [
               %{
                 "id" => Base.url_encode64(passkey.credential_id, padding: false),
                 "type" => "public-key"
               }
             ]
    end
  end

  describe "verify_passkey_registration/3" do
    setup :begin_passkey_registration

    test "returns a built, unsaved passkey from a valid attestation response",
         %{user: user, challenge: challenge, credential: credential} do
      assert {:ok, %UserPasskey{} = passkey} =
               Webauthn.verify_passkey_registration(user, credential, challenge)

      assert Ecto.get_meta(passkey, :state) == :built
      assert passkey.id == nil
      assert passkey.user_id == user.id
      assert passkey.device_name == nil
      assert passkey.sign_count == 0
      assert passkey.aaguid == nil
      assert passkey.credential_id == Base.url_decode64!(credential["rawId"], padding: false)
      assert :erlang.binary_to_term(passkey.public_key, [:safe])
    end

    test "returns an error when the attestation object is not valid CBOR",
         %{
           user: user,
           challenge: challenge,
           credential: credential
         } do
      invalid_credential =
        put_in(
          credential["response"]["attestationObject"],
          Base.url_encode64("not cbor", padding: false)
        )

      assert {:error, _reason} =
               Webauthn.verify_passkey_registration(
                 user,
                 invalid_credential,
                 challenge
               )
    end

    test "returns an error when the challenge doesn't match", %{user: user, challenge: challenge} do
      {other_challenge, _options} = Webauthn.begin_passkey_registration(user)
      credential = fake_registration_response(other_challenge)

      assert {:error, _reason} =
               Webauthn.verify_passkey_registration(user, credential, challenge)
    end

    test "returns an error when the user was not verified by the authenticator",
         %{user: user, challenge: challenge} do
      credential = fake_registration_response(challenge, user_verified: false)

      assert {:error, _reason} =
               Webauthn.verify_passkey_registration(user, credential, challenge)
    end
  end

  describe "save_passkey/2" do
    setup :begin_passkey_registration

    setup %{user: user, challenge: challenge, credential: credential} do
      {:ok, passkey} =
        Webauthn.verify_passkey_registration(user, credential, challenge)

      %{passkey: passkey}
    end

    test "persists the passkey with the given device name", %{user: user, passkey: passkey} do
      assert {:ok, %UserPasskey{} = saved_passkey} =
               Webauthn.register_passkey(passkey, %{"device_name" => "My device"})

      assert saved_passkey.id != nil
      assert saved_passkey.user_id == user.id
      assert saved_passkey.device_name == "My device"
      assert saved_passkey.credential_id == passkey.credential_id
    end

    test "returns a changeset error when the device name is invalid", %{passkey: passkey} do
      assert {:error, %Ecto.Changeset{}} =
               Webauthn.register_passkey(passkey, %{"device_name" => ""})

      too_long = String.duplicate("a", 256)

      assert {:error, %Ecto.Changeset{}} =
               Webauthn.register_passkey(passkey, %{"device_name" => too_long})
    end
  end

  defp begin_passkey_registration(%{user: user}) do
    {challenge, _options} = Webauthn.begin_passkey_registration(user)
    credential = fake_registration_response(challenge)

    %{challenge: challenge, credential: credential}
  end
end
