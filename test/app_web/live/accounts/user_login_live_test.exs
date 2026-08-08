defmodule AppWeb.UserLoginLiveTest do
  use AppWeb.ConnCase, async: true

  import ExUnit.CaptureLog
  import Phoenix.LiveViewTest
  import App.AccountsFixtures
  import App.WebauthnFixtures

  alias App.Accounts.Webauthn

  describe "Log in page" do
    test "renders log in page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/users/log_in")

      assert html =~ "Sign in to your account"
      assert html =~ "Forgot your password?"
      assert html =~ "Create an account"
    end

    test "redirects if already logged in", %{conn: conn} do
      result =
        conn
        |> log_in_user(user_fixture())
        |> live(~p"/users/log_in")
        |> follow_redirect(conn, "/")

      assert {:ok, _conn} = result
    end
  end

  describe "user login" do
    test "redirects if user login with valid credentials", %{conn: conn} do
      password = "123456789abcd"
      user = user_fixture(%{password: password})

      {:ok, lv, _html} = live(conn, ~p"/users/log_in")

      form =
        form(lv, "#login_form", user: %{email: user.email, password: password, remember_me: true})

      conn = submit_form(form, conn)

      assert redirected_to(conn) == ~p"/"
    end

    test "redirects to login page with a flash error if there are no valid credentials", %{
      conn: conn
    } do
      {:ok, lv, _html} = live(conn, ~p"/users/log_in")

      form =
        form(lv, "#login_form",
          user: %{email: "test@email.com", password: "123456", remember_me: true}
        )

      conn = submit_form(form, conn)

      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Invalid email or password"

      assert redirected_to(conn) == "/users/log_in"
    end
  end

  describe "passkey login" do
    test "pushes a conditional (autofill) authentication challenge on mount", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/log_in")

      assert_push_event lv, "passkey:conditional_authenticate", %{options: options}
      assert map_size(options) == 5
      assert options["allowCredentials"] == []
      assert options["challenge"] |> is_binary()
      assert options["rpId"] == "localhost"
      assert options["timeout"] == 120_000
      assert options["userVerification"] == "required"
    end

    test "pushes a fresh challenge when the passkey button is clicked", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/log_in")
      assert_push_event lv, "passkey:conditional_authenticate", %{}

      lv |> element("button", "Sign in with a passkey") |> render_click()

      assert_push_event lv, "passkey:authenticate", %{options: options}
      assert options["userVerification"] == "required"
    end

    test "logs the user in on a valid passkey assertion", %{conn: conn} do
      user = user_fixture()
      {public_key, _private_key} = keypair = generate_keypair()
      credential_id = :crypto.strong_rand_bytes(16)

      user_passkey_fixture(user, %{
        credential_id: credential_id,
        public_key: :erlang.term_to_binary(cose_key_from_public_key(public_key)),
        sign_count: 0
      })

      {:ok, lv, _html} = live(conn, ~p"/users/log_in")
      assert_push_event lv, "passkey:conditional_authenticate", %{options: options}

      challenge = mounted_challenge(options)

      credential =
        fake_authentication_response(challenge, credential_id: credential_id, keypair: keypair)

      html = render_hook(lv, "passkey:authenticate_response", %{"response" => credential})

      assert html =~ "phx-trigger-action"
      [_, token] = Regex.run(~r/name="passkey_token" value="([^"]*)"/, html)
      assert AppWeb.UserAuth.verify_passkey_login_token(token).id == user.id
    end

    test "shows a flash error on an invalid passkey assertion", %{conn: conn} do
      user = user_fixture()
      {public_key, _private_key} = keypair = generate_keypair()
      credential_id = :crypto.strong_rand_bytes(16)

      user_passkey_fixture(user, %{
        credential_id: credential_id,
        public_key: :erlang.term_to_binary(cose_key_from_public_key(public_key)),
        sign_count: 0
      })

      {:ok, lv, _html} = live(conn, ~p"/users/log_in")
      assert_push_event lv, "passkey:conditional_authenticate", %{options: options}

      challenge = mounted_challenge(options)

      credential =
        fake_authentication_response(challenge,
          credential_id: credential_id,
          keypair: keypair,
          user_verified: false
        )

      logged =
        capture_log(fn ->
          html = render_hook(lv, "passkey:authenticate_response", %{"response" => credential})

          assert html =~ "Passkey sign-in failed"
        end)

      assert logged =~
               "An error occured while verifying passkey authentication: {:wax, %Wax.InvalidClientDataError{reason: :user_not_verified}}"
    end

    test "shows a flash error when the client reports a WebAuthn error", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/log_in")

      html =
        render_hook(lv, "passkey:authenticate_error", %{"message" => "The operation was aborted"})

      assert html =~ "The operation was aborted"
    end
  end

  defp mounted_challenge(options) do
    {fresh_challenge, _options} = Webauthn.begin_passkey_authentication()
    %{fresh_challenge | bytes: Base.url_decode64!(options["challenge"], padding: false)}
  end

  describe "login navigation" do
    test "redirects to registration page when the Register button is clicked", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/log_in")

      {:ok, _login_live, login_html} =
        lv
        |> element("a", "Create an account")
        |> render_click()
        |> follow_redirect(conn, ~p"/users/register")

      assert login_html =~ "Register"
    end

    test "redirects to forgot password page when the Forgot Password button is clicked", %{
      conn: conn
    } do
      {:ok, lv, _html} = live(conn, ~p"/users/log_in")

      {:ok, _forgot_password_live, forgot_password_html} =
        lv
        |> element("a", "Forgot your password?")
        |> render_click()
        |> follow_redirect(conn, ~p"/users/reset_password")

      assert forgot_password_html =~ "Forgot your password?"
    end
  end
end
