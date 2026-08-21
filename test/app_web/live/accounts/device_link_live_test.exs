defmodule AppWeb.DeviceLinkLiveTest do
  use AppWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import App.AccountsFixtures
  import App.WebauthnFixtures

  alias App.Accounts
  alias App.Accounts.UserToken
  alias App.Repo

  setup do
    user = user_fixture()
    token = Accounts.create_device_link_token(user)
    %{user: user, token: token}
  end

  describe "with a valid token" do
    test "shows the passkey registration intro", %{conn: conn, token: token} do
      {:ok, _lv, html} = live(conn, ~p"/devices/link/#{token}")

      assert html =~ "You&#39;re about to register this device"
      assert html =~ "Add passkey"
    end
  end

  describe "with an invalid or expired token" do
    test "redirects home with a flash message", %{conn: conn} do
      assert {:error, {:redirect, to}} = live(conn, ~p"/devices/link/invalid")

      assert to == %{
               flash: %{"error" => "This link is invalid or has expired."},
               to: ~p"/"
             }
    end

    test "redirects home once the token has expired", %{conn: conn, token: token} do
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])

      assert {:error, {:redirect, to}} = live(conn, ~p"/devices/link/#{token}")
      assert to.to == ~p"/"
    end
  end

  describe "registering a passkey" do
    test "registers the passkey, consumes the token, and prepares device sign-in", %{
      conn: conn,
      token: token,
      user: user
    } do
      {:ok, lv, _html} = live(conn, ~p"/devices/link/#{token}")

      html = start_and_resolve_registration(lv)
      assert html =~ "Device name"

      result =
        lv
        |> form("#passkey-registration-form", %{
          "user_passkey" => %{"device_name" => "My new phone"}
        })
        |> render_submit()

      assert [passkey] = Accounts.list_user_passkeys(user)
      assert passkey.device_name == "My new phone"

      assert result =~ "phx-trigger-action"
      [_, passkey_token] = Regex.run(~r/name="passkey_token" value="([^"]*)"/, result)
      assert AppWeb.UserAuth.verify_passkey_login_token(passkey_token).id == user.id

      # The link is single-use: it can no longer be redeemed.
      refute Accounts.get_user_by_device_link_token(token)
      assert {:error, {:redirect, %{to: "/"}}} = live(conn, ~p"/devices/link/#{token}")
    end
  end

  defp start_and_resolve_registration(lv) do
    lv |> element("[phx-click=start_register]") |> render_click()
    assert_push_event(lv, "register", %{options: options})

    challenge = challenge_from_options(options)
    credential = fake_registration_response(challenge)

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
