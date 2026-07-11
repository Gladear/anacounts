defmodule AppWeb.UserSettingsPasskeysLiveTest do
  use AppWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import App.AccountsFixtures

  alias App.Accounts

  setup [:register_and_log_in_user]

  describe "list passkeys" do
    test "shows the empty state when the user has no passkeys", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/settings/passkeys")

      html = render_async(lv)
      assert html =~ "No passkeys registered yet."
    end

    test "lists the user's passkeys", %{conn: conn, user: user} do
      passkey = user_passkey_fixture(user, device_name: "My iPhone")
      _other_user_passkey = user_passkey_fixture(user_fixture(), device_name: "Not mine")

      {:ok, lv, _html} = live(conn, ~p"/users/settings/passkeys")

      html = render_async(lv)
      assert html =~ "My iPhone"
      refute html =~ "Not mine"
      assert has_element?(lv, "#passkeys-#{passkey.id}")
    end
  end

  describe "rename passkey" do
    setup %{conn: conn, user: user} do
      passkey = user_passkey_fixture(user, device_name: "Old device name")

      {:ok, lv, _html} = live(conn, ~p"/users/settings/passkeys")
      render_async(lv)

      html =
        lv
        |> element("[phx-click=begin_rename][phx-value-id='#{passkey.id}']")
        |> render_click()

      %{passkey: passkey, lv: lv, html: html}
    end

    test "shows the rename form pre-filled with the current name", %{html: html} do
      assert html =~ ~s(value="Old device name")
    end

    test "renames the passkey", %{lv: lv, user: user, passkey: passkey} do
      html =
        lv
        |> form("form", %{"rename" => %{"device_name" => "New device name"}})
        |> render_submit()

      assert html =~ "New device name"
      refute html =~ "Old device name"
      assert Accounts.get_user_passkey!(user, passkey.id).device_name == "New device name"
    end

    test "validates the name on change", %{lv: lv} do
      html =
        lv
        |> form("form", %{"rename" => %{"device_name" => ""}})
        |> render_change()

      assert html =~ "can&#39;t be blank"
    end

    test "renders an error and keeps the changeset errors when submission fails", %{lv: lv} do
      html =
        lv
        |> form("form", %{"rename" => %{"device_name" => ""}})
        |> render_submit()

      assert html =~ "can&#39;t be blank"
    end

    test "cancels the rename", %{lv: lv} do
      lv
      |> element("[phx-click=cancel_rename]")
      |> render_click()

      refute has_element?(lv, "form")
    end
  end

  describe "delete passkey" do
    test "deletes the passkey when the user has more than one", %{conn: conn, user: user} do
      passkey = user_passkey_fixture(user, device_name: "To delete")
      _kept_passkey = user_passkey_fixture(user, device_name: "Kept")

      {:ok, lv, _html} = live(conn, ~p"/users/settings/passkeys")
      render_async(lv)

      html =
        lv
        |> element("[phx-click=delete][phx-value-id='#{passkey.id}']")
        |> render_click()

      refute html =~ "To delete"
      assert html =~ "Kept"
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_user_passkey!(user, passkey.id) end
    end

    test "shows an error when deleting the user's last passkey", %{conn: conn, user: user} do
      passkey = user_passkey_fixture(user, device_name: "Only passkey")

      {:ok, lv, _html} = live(conn, ~p"/users/settings/passkeys")
      render_async(lv)

      html =
        lv
        |> element("[phx-click=delete][phx-value-id='#{passkey.id}']")
        |> render_click()

      assert html =~ "You must keep at least one passkey. Add another device first."
      assert html =~ "Only passkey"
      assert Accounts.get_user_passkey!(user, passkey.id)
    end
  end

  describe "add a passkey" do
    test "navigates to the dedicated passkey creation page", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/settings/passkeys")
      render_async(lv)

      {:ok, _new_lv, html} =
        lv
        |> element("a", "Add a passkey")
        |> render_click()
        |> follow_redirect(conn, ~p"/users/settings/passkeys/new")

      assert html =~ "Add a passkey"
    end
  end
end
