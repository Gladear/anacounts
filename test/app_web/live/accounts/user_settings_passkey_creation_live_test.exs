defmodule AppWeb.UserSettingsPasskeyCreationLiveTest do
  use AppWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import App.WebauthnFixtures

  alias App.Accounts

  setup [:register_and_log_in_user]

  describe "intro" do
    test "shows an explanation, an add passkey button and a cancel link", %{conn: conn} do
      {:ok, lv, html} = live(conn, ~p"/users/settings/passkeys/new")

      assert html =~ "passkey"
      assert has_element?(lv, "[phx-click=start_register]", "Add passkey")
      assert has_element?(lv, "a", "Cancel")
      refute has_element?(lv, "form")
    end

    test "cancelling navigates back to the passkeys list", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/settings/passkeys/new")

      {:ok, _new_lv, html} =
        lv
        |> element("a", "Cancel")
        |> render_click()
        |> follow_redirect(conn, ~p"/users/settings/passkeys")

      assert html =~ "Registered passkeys"
    end

    test "shows the client-side error message when the browser call fails", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/settings/passkeys/new")

      html =
        render_hook(lv, "register_error", %{"message" => "The operation was aborted"})

      assert html =~ "The operation was aborted"
      assert has_element?(lv, "[phx-click=start_register]", "Add passkey")
    end
  end

  describe "starting registration" do
    test "pushes a register event with the WebAuthn options", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/settings/passkeys/new")

      lv |> element("[phx-click=start_register]") |> render_click()

      assert_push_event(lv, "register", %{options: _options})
    end

    test "shows the device name form once the browser resolves the registration", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/settings/passkeys/new")

      lv |> element("[phx-click=start_register]") |> render_click()
      assert_push_event(lv, "register", %{options: options})

      challenge = challenge_from_options(options)
      credential = fake_registration_response(challenge)

      html = render_hook(lv, "register_response", %{"response" => credential})

      assert html =~ "Device name"
      refute html =~ "Add passkey"
    end

    test "shows an error and goes back to the intro step when verification fails", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/settings/passkeys/new")

      lv |> element("[phx-click=start_register]") |> render_click()
      assert_push_event(lv, "register", %{options: options})

      challenge = challenge_from_options(options)

      # The authenticator response doesn't have the user-verified flag set,
      # even though the challenge requires it, so `Wax.register` rejects it.
      credential = fake_registration_response(challenge, user_verified: false)

      html = render_hook(lv, "register_response", %{"response" => credential})

      assert html =~ "Registration failed, please try again."
      assert has_element?(lv, "[phx-click=start_register]", "Add passkey")
      refute html =~ "Device name"
    end
  end

  describe "naming" do
    test "validates the device name on change", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/settings/passkeys/new")
      start_and_resolve_registration(lv)

      html =
        lv
        |> form("form", %{"user_passkey" => %{"device_name" => ""}})
        |> render_change()

      assert html =~ "can&#39;t be blank"
    end

    test "shows an error when the name is too long", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/settings/passkeys/new")
      start_and_resolve_registration(lv)

      html =
        lv
        |> form("form", %{"user_passkey" => %{"device_name" => String.duplicate("a", 256)}})
        |> render_change()

      assert html =~ "should be at most 255 characters"
    end

    test "saves the passkey and navigates back to the list on a valid name", %{
      conn: conn,
      user: user
    } do
      {:ok, lv, _html} = live(conn, ~p"/users/settings/passkeys/new")
      start_and_resolve_registration(lv)

      result =
        lv
        |> form("form", %{"user_passkey" => %{"device_name" => "My phone"}})
        |> render_submit()

      assert {:ok, new_lv, html} = follow_redirect(result, conn)

      assert html =~ "Passkey added successfully."
      assert [passkey] = Accounts.list_user_passkeys(user)
      assert passkey.device_name == "My phone"
      assert has_element?(new_lv, "#passkeys-#{passkey.id}")
    end

    test "shows a changeset error and stays on the naming step when the name is invalid", %{
      conn: conn
    } do
      {:ok, lv, _html} = live(conn, ~p"/users/settings/passkeys/new")
      start_and_resolve_registration(lv)

      html =
        lv
        |> form("form", %{"user_passkey" => %{"device_name" => ""}})
        |> render_submit()

      assert html =~ "can&#39;t be blank"
    end
  end

  defp start_and_resolve_registration(lv, fixture_opts \\ []) do
    lv |> element("[phx-click=start_register]") |> render_click()
    assert_push_event(lv, "register", %{options: options})

    challenge = challenge_from_options(options)
    credential = fake_registration_response(challenge, fixture_opts)

    render_hook(lv, "register_response", %{"response" => credential})
  end

  defp challenge_from_options(options) do
    origin = Application.fetch_env!(:app, App.Accounts.Webauthn) |> Keyword.fetch!(:origin)

    %Wax.Challenge{
      type: :attestation,
      bytes: Base.url_decode64!(options["challenge"], padding: false),
      origin: origin,
      rp_id: options["rp"]["id"],
      issued_at: System.system_time(:second),
      attestation: "none",
      user_verification: "required"
    }
  end
end
