defmodule AppWeb.AdminUserResetPasswordLiveTest do
  use AppWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import App.AccountsFixtures

  alias App.Accounts
  alias App.Accounts.UserToken
  alias App.Repo

  setup %{conn: conn} do
    %{conn: log_in_user(conn, user_fixture() |> make_user_admin()), target: user_fixture()}
  end

  describe "Admin reset password page" do
    test "renders the form", %{conn: conn} do
      {:ok, lv, html} = live(conn, ~p"/admin/users/reset_password")

      assert html =~ "Reset a user&#39;s password"
      assert has_element?(lv, "#admin_reset_password_form")
    end

    test "autofills the email from the query parameters", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/admin/users/reset_password?email=someone@example.com")

      assert has_element?(lv, ~s|#admin_reset_password_form input[value="someone@example.com"]|)
    end

    test "responds with a 404 if the user is not an admin", %{conn: conn} do
      conn = conn |> log_in_user(user_fixture()) |> get(~p"/admin/users/reset_password")

      assert response(conn, 404)
    end

    test "redirects to the login page if the user is not authenticated" do
      assert {:error, {:redirect, %{to: "/users/log_in"}}} =
               live(build_conn(), ~p"/admin/users/reset_password")
    end
  end

  describe "Reset link" do
    test "generates a reset password link", %{conn: conn, target: %{id: target_id} = target} do
      {:ok, lv, _html} = live(conn, ~p"/admin/users/reset_password")

      html =
        lv
        |> form("#admin_reset_password_form", user: %{"email" => target.email})
        |> render_submit()

      assert html =~ target.email

      [_, token] = Regex.run(~r{/users/reset_password/([\w-]+)"}, html)
      assert %{id: ^target_id} = Accounts.get_user_by_reset_password_token(token)

      lv |> element("a", "Reset another password") |> render_click()
      assert has_element?(lv, "#admin_reset_password_form")
    end

    test "shows an error if the user does not exist", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/admin/users/reset_password")

      html =
        lv
        |> form("#admin_reset_password_form", user: %{"email" => "unknown@example.com"})
        |> render_submit()

      assert html =~ "No user found with this email"
      assert has_element?(lv, ~s|#admin_reset_password_form input[value="unknown@example.com"]|)
      refute Repo.get_by(UserToken, context: "reset_password")
    end
  end
end
