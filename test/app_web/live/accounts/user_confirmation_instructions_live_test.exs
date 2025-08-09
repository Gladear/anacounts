defmodule AppWeb.UserConfirmationInstructionsLiveTest do
  use AppWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias App.Accounts
  alias App.Repo

  setup :register_and_log_in_user

  describe "Resend confirmation" do
    test "renders the resend confirmation page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/users/confirm")
      assert html =~ "Confirm your account"
      assert html =~ "Send instructions"
    end

    test "sends a new confirmation token", %{conn: conn, user: user} do
      {:ok, lv, _html} = live(conn, ~p"/users/confirm")

      {:ok, conn} =
        lv
        |> element("button", "Send instructions")
        |> render_click()
        |> follow_redirect(conn, ~p"/users/settings")

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "If your email has not been confirmed yet"

      assert Repo.get_by!(Accounts.UserToken, user_id: user.id, context: "confirm")
    end

    test "does not send confirmation token if user is confirmed", %{conn: conn, user: user} do
      Repo.update!(Accounts.User.confirm_changeset(user))

      {:ok, lv, _html} = live(conn, ~p"/users/confirm")

      {:ok, conn} =
        lv
        |> element("button", "Send instructions")
        |> render_click()
        |> follow_redirect(conn, ~p"/users/settings")

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "If your email has not been confirmed yet"

      refute Repo.get_by(Accounts.UserToken, user_id: user.id, context: "confirm")
    end
  end
end
