defmodule AppWeb.UserSettingsLiveTest do
  use AppWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import App.AccountsFixtures

  describe "Settings page" do
    test "renders settings page", %{conn: conn} do
      {:ok, _lv, html} =
        conn
        |> log_in_user(user_fixture())
        |> live(~p"/users/settings")

      assert html =~ "Change email"
      assert html =~ "Change password"
      assert html =~ "Disconnect"
    end

    test "redirects if user is not logged in", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/users/settings")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/log_in"
      assert %{"error" => "You must log in to access this page."} = flash
    end

    test "renders the passkey banner when the user has no passkey", %{conn: conn} do
      {:ok, _lv, html} =
        conn
        |> log_in_user(user_fixture())
        |> live(~p"/users/settings")

      assert html =~ "Register a passkey"
    end

    test "does not render the passkey banner when the user has a passkey", %{conn: conn} do
      user = user_fixture()
      _user_passkey = user_passkey_fixture(user)

      {:ok, _lv, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/users/settings")

      refute html =~ "Register a passkey"
    end
  end
end
