defmodule AppWeb.PageControllerTest do
  use AppWeb.ConnCase, async: true

  import App.AccountsFixtures

  describe "GET :index" do
    test "redirects authenticated user to home page", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      conn = get(conn, ~p"/")
      assert redirected_to(conn) == ~p"/books"
    end

    test "redirects non-authenticated user to new session page", %{conn: conn} do
      conn = get(conn, ~p"/")
      assert redirected_to(conn) == ~p"/users/log_in"
    end
  end
end
