defmodule AppWeb.UserForgotPasswordLiveTest do
  use AppWeb.ConnCase, async: true

  import App.AccountsFixtures
  import Phoenix.LiveViewTest

  alias App.Accounts.UserToken
  alias App.Repo

  describe "Forgot password page" do
    test "renders email page", %{conn: conn} do
      {:ok, lv, html} = live(conn, ~p"/users/reset_password")

      assert html =~ "Forgot your password?"
      assert has_element?(lv, ~s|a[href="#{~p"/users/log_in"}"]|, "Sign in to your account")
    end

    test "redirects if already logged in", %{conn: conn} do
      result =
        conn
        |> log_in_user(user_fixture())
        |> live(~p"/users/reset_password")
        |> follow_redirect(conn, ~p"/")

      assert {:ok, _conn} = result
    end
  end

  describe "Reset link" do
    test "displays a link to the admin reset password page", %{conn: conn} do
      user = user_fixture()
      {:ok, lv, _html} = live(conn, ~p"/users/reset_password")

      lv
      |> form("#reset_password_form", user: %{"email" => user.email})
      |> render_submit()

      admin_url = url(~p"/admin/users/reset_password?#{[email: user.email]}")
      assert has_element?(lv, ~s|input[value="#{admin_url}"]|)
      refute Repo.get_by(UserToken, user_id: user.id)
    end
  end
end
