defmodule AppWeb.UserConfirmationControllerTest do
  use AppWeb.ConnCase, async: true

  import App.AccountsFixtures

  alias App.Accounts
  alias App.Repo

  setup :register_and_log_in_user

  setup %{user: user} do
    token =
      extract_user_token(fn url ->
        Accounts.deliver_user_confirmation_instructions(user, url)
      end)

    %{token: token}
  end

  describe "GET /users/confirm/:token" do
    test "confirms the user", %{conn: conn, user: user, token: token} do
      conn = get(conn, ~p"/users/confirm/#{token}")

      assert Phoenix.Flash.get(conn.assigns.flash, :info) ==
               "Your account was confirmed."

      assert redirected_to(conn) == ~p"/users/settings"
      assert Repo.reload!(user).confirmed_at != nil
    end

    test "does not confirm user with invalid token", %{conn: conn, user: user} do
      conn = get(conn, ~p"/users/confirm/invalid")

      assert Phoenix.Flash.get(conn.assigns.flash, :error) ==
               "This confirmation link is invalid or it has expired."

      assert redirected_to(conn) == ~p"/users/settings"
      assert Repo.reload!(user).confirmed_at == nil
    end
  end
end
