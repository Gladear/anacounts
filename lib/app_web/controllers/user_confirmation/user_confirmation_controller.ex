defmodule AppWeb.UserConfirmationController do
  use AppWeb, :controller

  alias App.Accounts

  def update(conn, %{"token" => token}) do
    with nil <- conn.assigns.current_user.confirmed_at,
         :error <- Accounts.confirm_user(conn.assigns.current_user, token) do
      conn
      |> put_flash(:error, gettext("This confirmation link is invalid or it has expired."))
      |> redirect(to: ~p"/users/settings")
    else
      _ ->
        conn
        |> put_flash(:info, gettext("Your account was confirmed."))
        |> redirect(to: ~p"/users/settings")
    end
  end
end
