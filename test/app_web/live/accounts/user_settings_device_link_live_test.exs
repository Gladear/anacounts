defmodule AppWeb.UserSettingsDeviceLinkLiveTest do
  use AppWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias App.Accounts.UserToken
  alias App.Repo

  setup [:register_and_log_in_user]

  test "shows a copyable device-link URL and its QR code", %{conn: conn, user: user} do
    {:ok, lv, html} = live(conn, ~p"/users/settings/passkeys/link-device")

    assert html =~ "svg"

    device_link_url =
      lv
      |> element("#device_link_url")
      |> render()

    assert [_, url] = Regex.run(~r/value="([^"]+)"/, device_link_url)
    assert [_, token] = Regex.run(~r{/devices/link/([^"]+)$}, url)

    {:ok, decoded_token} = Base.url_decode64(token, padding: false)
    assert user_token = Repo.get_by(UserToken, token: :crypto.hash(:sha256, decoded_token))
    assert user_token.user_id == user.id
    assert user_token.context == "device_link"
  end

  test "cancelling navigates back to the passkeys list", %{conn: conn} do
    {:ok, lv, _html} = live(conn, ~p"/users/settings/passkeys/link-device")

    {:ok, _new_lv, html} =
      lv
      |> element("a", "Cancel")
      |> render_click()
      |> follow_redirect(conn, ~p"/users/settings/passkeys")

    assert html =~ "Registered passkeys"
  end
end
