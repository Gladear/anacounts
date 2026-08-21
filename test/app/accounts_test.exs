defmodule App.AccountsTest do
  use App.DataCase, async: true

  import App.AccountsFixtures

  alias App.Accounts
  alias App.Accounts.User
  alias App.Accounts.UserToken

  @valid_user_password "initial valid password"

  describe "get_user_by_email/1" do
    test "does not return the user if the email does not exist" do
      refute Accounts.get_user_by_email("unknown@example.com")
    end

    test "returns the user if the email exists" do
      %{id: id} = user = user_fixture()
      assert %User{id: ^id} = Accounts.get_user_by_email(user.email)
    end
  end

  describe "get_user_by_email_and_password/2" do
    test "does not return the user if the email does not exist" do
      refute Accounts.get_user_by_email_and_password("unknown@example.com", "hello world!")
    end

    test "does not return the user if the password is not valid" do
      user = user_fixture()
      refute Accounts.get_user_by_email_and_password(user.email, "invalid")
    end

    test "returns the user if the email and password are valid" do
      %{id: id} = user = user_fixture(password: @valid_user_password)

      assert %User{id: ^id} =
               Accounts.get_user_by_email_and_password(user.email, @valid_user_password)
    end
  end

  describe "get_user!/1" do
    test "raises if id is invalid" do
      assert_raise Ecto.NoResultsError, fn ->
        Accounts.get_user!(-1)
      end
    end

    test "returns the user with the given id" do
      %{id: id} = user = user_fixture()
      assert %User{id: ^id} = Accounts.get_user!(user.id)
    end
  end

  describe "register_user/1" do
    test "requires email and password to be set" do
      {:error, changeset} = Accounts.register_user(%{})

      assert %{
               email: ["can't be blank"],
               password: ["can't be blank"]
             } = errors_on(changeset)
    end

    test "validates email and password when given" do
      {:error, changeset} = Accounts.register_user(%{email: "not valid", password: "not valid"})

      assert %{
               email: ["must have the @ sign and no spaces"],
               password: ["should be at least 12 character(s)"]
             } = errors_on(changeset)
    end

    test "validates maximum values for email and password for security" do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Accounts.register_user(%{email: too_long, password: too_long})
      assert "should be at most 160 character(s)" in errors_on(changeset).email
      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "validates email uniqueness" do
      %{email: email} = user_fixture()

      {:error, changeset} =
        Accounts.register_user(%{
          email: email,
          password: @valid_user_password
        })

      assert "has already been taken" in errors_on(changeset).email

      # Now try with the upper cased email too, to check that email case is ignored.
      {:error, changeset_upcase} =
        Accounts.register_user(%{
          email: String.upcase(email),
          password: @valid_user_password
        })

      assert "has already been taken" in errors_on(changeset_upcase).email
    end

    test "registers users with a hashed password" do
      email = unique_user_email()
      {:ok, user} = Accounts.register_user(user_attributes(email: email))
      assert user.email == email
      assert is_binary(user.hashed_password)
      assert is_nil(user.password)
    end
  end

  describe "change_user_registration/2" do
    test "returns a changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_user_registration(%User{})
      assert changeset.required == [:password, :email]
    end

    test "allows fields to be set" do
      email = unique_user_email()
      password = @valid_user_password

      changeset =
        Accounts.change_user_registration(
          %User{},
          user_attributes(email: email, password: password)
        )

      assert changeset.valid?
      assert get_change(changeset, :email) == email
      assert get_change(changeset, :password) == password
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "change_user_email/2" do
    test "returns a user changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_user_email(%User{})
      assert changeset.required == [:email]
    end
  end

  describe "apply_user_email/3" do
    setup do
      %{user: user_fixture(password: @valid_user_password)}
    end

    test "requires email to change", %{user: user} do
      {:error, changeset} = Accounts.apply_user_email(user, @valid_user_password, %{})
      assert %{email: ["did not change"]} = errors_on(changeset)
    end

    test "validates email", %{user: user} do
      {:error, changeset} =
        Accounts.apply_user_email(user, @valid_user_password, %{email: "not valid"})

      assert %{email: ["must have the @ sign and no spaces"]} = errors_on(changeset)
    end

    test "validates maximum value for email for security", %{user: user} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        Accounts.apply_user_email(user, @valid_user_password, %{email: too_long})

      assert "should be at most 160 character(s)" in errors_on(changeset).email
    end

    test "validates email uniqueness", %{user: user} do
      %{email: email} = user_fixture()

      {:error, changeset} = Accounts.apply_user_email(user, @valid_user_password, %{email: email})

      assert "has already been taken" in errors_on(changeset).email
    end

    test "validates current password", %{user: user} do
      {:error, changeset} =
        Accounts.apply_user_email(user, "invalid", %{email: unique_user_email()})

      assert %{current_password: ["is not valid"]} = errors_on(changeset)
    end

    test "applies the email without persisting it", %{user: user} do
      email = unique_user_email()
      {:ok, user} = Accounts.apply_user_email(user, @valid_user_password, %{email: email})
      assert user.email == email
      assert Accounts.get_user!(user.id).email != email
    end
  end

  describe "deliver_user_update_email_instructions/3" do
    setup do
      %{user: user_fixture()}
    end

    test "sends token through notification", %{user: user} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_update_email_instructions(user, "current@example.com", url)
        end)

      {:ok, decoded_token} = Base.url_decode64(token, padding: false)
      assert user_token = Repo.get_by(UserToken, token: :crypto.hash(:sha256, decoded_token))
      assert user_token.user_id == user.id
      assert user_token.sent_to == user.email
      assert user_token.context == "change:current@example.com"
    end
  end

  describe "update_user_email/2" do
    setup do
      user = user_fixture()
      email = unique_user_email()

      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_update_email_instructions(%{user | email: email}, user.email, url)
        end)

      %{user: user, token: token, email: email}
    end

    test "updates the email with a valid token", %{user: user, token: token, email: email} do
      assert Accounts.update_user_email(user, token) == :ok
      changed_user = Repo.get!(User, user.id)
      assert changed_user.email != user.email
      assert changed_user.email == email
      refute Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not update email with invalid token", %{user: user} do
      assert Accounts.update_user_email(user, "oops") == :error
      assert Repo.get!(User, user.id).email == user.email
      assert Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not update email if user email changed", %{user: user, token: token} do
      assert Accounts.update_user_email(%{user | email: "current@example.com"}, token) == :error
      assert Repo.get!(User, user.id).email == user.email
      assert Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not update email if token expired", %{user: user, token: token} do
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      assert Accounts.update_user_email(user, token) == :error
      assert Repo.get!(User, user.id).email == user.email
      assert Repo.get_by(UserToken, user_id: user.id)
    end
  end

  describe "change_user_password/2" do
    test "returns a user changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_user_password(%User{})
      assert changeset.required == [:password]
    end

    test "allows fields to be set" do
      changeset =
        Accounts.change_user_password(%User{}, %{
          "password" => "new valid password"
        })

      assert changeset.valid?
      assert get_change(changeset, :password) == "new valid password"
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "update_user_password/3" do
    setup do
      %{user: user_fixture(password: @valid_user_password)}
    end

    test "validates password", %{user: user} do
      {:error, changeset} =
        Accounts.update_user_password(user, @valid_user_password, %{
          password: "not valid",
          password_confirmation: "another"
        })

      assert %{
               password: ["should be at least 12 character(s)"],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{user: user} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        Accounts.update_user_password(user, @valid_user_password, %{password: too_long})

      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "validates current password", %{user: user} do
      {:error, changeset} =
        Accounts.update_user_password(user, "invalid", %{password: @valid_user_password})

      assert %{current_password: ["is not valid"]} = errors_on(changeset)
    end

    test "updates the password", %{user: user} do
      {:ok, user} =
        Accounts.update_user_password(user, @valid_user_password, %{
          password: "new valid password"
        })

      assert is_nil(user.password)
      assert Accounts.get_user_by_email_and_password(user.email, "new valid password")
    end

    test "deletes all tokens for the given user", %{user: user} do
      _ = Accounts.generate_user_session_token(user)

      {:ok, _} =
        Accounts.update_user_password(user, @valid_user_password, %{
          password: "new valid password"
        })

      refute Repo.get_by(UserToken, user_id: user.id)
    end
  end

  describe "generate_user_session_token/1" do
    setup do
      %{user: user_fixture()}
    end

    test "generates a token", %{user: user} do
      token = Accounts.generate_user_session_token(user)
      assert user_token = Repo.get_by(UserToken, token: token)
      assert user_token.context == "session"

      # Creating the same token for another user should fail
      assert_raise Ecto.ConstraintError, fn ->
        Repo.insert!(%UserToken{
          token: user_token.token,
          user_id: user_fixture().id,
          context: "session"
        })
      end
    end
  end

  describe "get_user_by_session_token/1" do
    setup do
      user = user_fixture()
      token = Accounts.generate_user_session_token(user)
      %{user: user, token: token}
    end

    test "returns user by token", %{user: user, token: token} do
      assert session_user = Accounts.get_user_by_session_token(token)
      assert session_user.id == user.id
    end

    test "does not return user for invalid token" do
      refute Accounts.get_user_by_session_token("oops")
    end

    test "does not return user for expired token", %{token: token} do
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Accounts.get_user_by_session_token(token)
    end
  end

  describe "delete_user_session_token/1" do
    test "deletes the token" do
      user = user_fixture()
      token = Accounts.generate_user_session_token(user)
      assert Accounts.delete_user_session_token(token) == :ok
      refute Accounts.get_user_by_session_token(token)
    end
  end

  describe "deliver_user_reset_password_instructions/2" do
    setup do
      %{user: user_fixture()}
    end

    test "sends token through notification", %{user: user} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_reset_password_instructions(user, url)
        end)

      {:ok, decoded_token} = Base.url_decode64(token, padding: false)
      assert user_token = Repo.get_by(UserToken, token: :crypto.hash(:sha256, decoded_token))
      assert user_token.user_id == user.id
      assert user_token.sent_to == user.email
      assert user_token.context == "reset_password"
    end
  end

  describe "get_user_by_reset_password_token/1" do
    setup do
      user = user_fixture()

      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_reset_password_instructions(user, url)
        end)

      %{user: user, token: token}
    end

    test "returns the user with valid token", %{user: %{id: id}, token: token} do
      assert %User{id: ^id} = Accounts.get_user_by_reset_password_token(token)
      assert Repo.get_by(UserToken, user_id: id)
    end

    test "does not return the user with invalid token", %{user: user} do
      refute Accounts.get_user_by_reset_password_token("oops")
      assert Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not return the user if token expired", %{user: user, token: token} do
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Accounts.get_user_by_reset_password_token(token)
      assert Repo.get_by(UserToken, user_id: user.id)
    end
  end

  describe "reset_user_password/2" do
    setup do
      %{user: user_fixture()}
    end

    test "validates password", %{user: user} do
      {:error, changeset} =
        Accounts.reset_user_password(user, %{
          password: "not valid",
          password_confirmation: "another"
        })

      assert %{
               password: ["should be at least 12 character(s)"],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{user: user} do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Accounts.reset_user_password(user, %{password: too_long})
      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "updates the password", %{user: user} do
      {:ok, updated_user} = Accounts.reset_user_password(user, %{password: "new valid password"})
      assert is_nil(updated_user.password)
      assert Accounts.get_user_by_email_and_password(user.email, "new valid password")
    end

    test "deletes all tokens for the given user", %{user: user} do
      _ = Accounts.generate_user_session_token(user)
      {:ok, _} = Accounts.reset_user_password(user, %{password: "new valid password"})
      refute Repo.get_by(UserToken, user_id: user.id)
    end
  end

  describe "list_user_passkeys/1" do
    test "returns an empty list when the user has no passkeys" do
      user = user_fixture()
      _other_user_passkey = user_passkey_fixture(user_fixture())
      assert Accounts.list_user_passkeys(user) == []
    end

    test "returns the user's passkeys ordered by name" do
      user = user_fixture()
      _other_user_passkey = user_passkey_fixture(user_fixture())
      passkey_b = user_passkey_fixture(user, device_name: "B passkey")
      passkey_a = user_passkey_fixture(user, device_name: "A passkey")

      assert Accounts.list_user_passkeys(user) |> Enum.map(& &1.id) == [
               passkey_a.id,
               passkey_b.id
             ]
    end
  end

  describe "count_user_passkeys/1" do
    test "returns 0 when the user has no passkeys" do
      user = user_fixture()
      assert Accounts.count_user_passkeys(user) == 0
    end

    test "returns the number of passkeys for the user" do
      user = user_fixture()
      for _ <- 1..3, do: user_passkey_fixture(user)
      _other_user_passkey = user_passkey_fixture(user_fixture())

      assert Accounts.count_user_passkeys(user) == 3
    end
  end

  describe "user_has_passkey?/1" do
    test "returns false when the user has no passkeys" do
      user = user_fixture()
      refute Accounts.user_has_passkey?(user)
    end

    test "returns true when the user has at least one passkey" do
      user = user_fixture()
      _user_passkey = user_passkey_fixture(user)

      assert Accounts.user_has_passkey?(user)
    end

    test "does not consider other users' passkeys" do
      user = user_fixture()
      _other_user_passkey = user_passkey_fixture(user_fixture())

      refute Accounts.user_has_passkey?(user)
    end
  end

  describe "get_user_passkey!/2" do
    test "returns the passkey when it belongs to the user" do
      user = user_fixture()
      user_passkey = user_passkey_fixture(user)

      assert Accounts.get_user_passkey!(user, user_passkey.id).id == user_passkey.id
    end

    test "raises when the passkey does not belong to the user" do
      user_passkey = user_passkey_fixture(user_fixture())
      other_user = user_fixture()

      assert_raise Ecto.NoResultsError, fn ->
        Accounts.get_user_passkey!(other_user, user_passkey.id)
      end
    end

    test "raises when the passkey does not exist" do
      user = user_fixture()

      assert_raise Ecto.NoResultsError, fn ->
        Accounts.get_user_passkey!(user, -1)
      end
    end
  end

  describe "rename_user_passkey/2" do
    test "renames the passkey" do
      user_passkey = user_passkey_fixture(user_fixture(), %{device_name: "Old name"})

      assert {:ok, updated_passkey} =
               Accounts.rename_user_passkey(user_passkey, %{device_name: "New name"})

      assert updated_passkey.device_name == "New name"
      assert Repo.reload!(user_passkey).device_name == "New name"
    end

    test "requires a device name" do
      user_passkey = user_passkey_fixture(user_fixture())

      assert {:error, changeset} = Accounts.rename_user_passkey(user_passkey, %{device_name: ""})
      assert %{device_name: ["can't be blank"]} = errors_on(changeset)
    end

    test "fails if name is too long" do
      user_passkey = user_passkey_fixture(user_fixture())

      too_long = String.duplicate("a", 256)

      assert {:error, changeset} =
               Accounts.rename_user_passkey(user_passkey, %{device_name: too_long})

      assert %{device_name: ["should be at most 255 character(s)"]} = errors_on(changeset)
    end
  end

  describe "delete_user_passkey/1" do
    test "deletes the passkey when the user has more than one" do
      user = user_fixture()
      user_passkey_fixture(user)
      user_passkey_to_delete = user_passkey_fixture(user)

      assert {:ok, _} = Accounts.delete_user_passkey(user_passkey_to_delete)
      assert Repo.reload(user_passkey_to_delete) == nil
    end

    test "returns an error when deleting the user's last passkey" do
      user_passkey = user_passkey_fixture(user_fixture())

      assert Accounts.delete_user_passkey(user_passkey) == {:error, :last_passkey}
      assert Repo.reload(user_passkey) != nil
    end
  end

  describe "create_device_link_token/1" do
    test "creates a device_link token for the user" do
      user = user_fixture()
      token = Accounts.create_device_link_token(user)

      {:ok, decoded_token} = Base.url_decode64(token, padding: false)
      assert user_token = Repo.get_by(UserToken, token: :crypto.hash(:sha256, decoded_token))
      assert user_token.user_id == user.id
      assert user_token.context == "device_link"
      assert user_token.sent_to == nil
    end
  end

  describe "get_user_by_device_link_token/1" do
    setup do
      user = user_fixture()
      token = Accounts.create_device_link_token(user)
      %{user: user, token: token}
    end

    test "returns the user with a valid token", %{user: %{id: id}, token: token} do
      assert %User{id: ^id} = Accounts.get_user_by_device_link_token(token)
    end

    test "does not return the user with an invalid token", %{user: user} do
      refute Accounts.get_user_by_device_link_token("oops")
      assert Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not return the user if the token expired", %{user: user, token: token} do
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Accounts.get_user_by_device_link_token(token)
      assert Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not return the user once the token has been consumed", %{user: user, token: token} do
      Accounts.delete_device_link_tokens(user)
      refute Accounts.get_user_by_device_link_token(token)
    end
  end

  describe "delete_device_link_tokens/1" do
    test "deletes the user's device_link tokens" do
      user = user_fixture()
      Accounts.create_device_link_token(user)

      assert Accounts.delete_device_link_tokens(user) == :ok
      refute Repo.get_by(UserToken, user_id: user.id, context: "device_link")
    end

    test "does not delete other users' device_link tokens" do
      other_user = user_fixture()
      Accounts.create_device_link_token(other_user)

      Accounts.delete_device_link_tokens(user_fixture())

      assert Repo.get_by(UserToken, user_id: other_user.id, context: "device_link")
    end
  end

  describe "inspect/2 for the User module" do
    test "does not include password" do
      refute inspect(%User{password: "123456"}) =~ "password: \"123456\""
    end
  end
end
