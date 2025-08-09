defmodule AppWeb.UserSessionController do
  use AppWeb, :controller

  alias App.Accounts
  alias AppWeb.UserAuth

  def create(conn, %{"_action" => "registered"} = params) do
    create_user_session(conn, params)
  end

  def create(conn, %{"_action" => "password_updated"} = params) do
    conn
    |> put_session(:user_return_to, ~p"/users/settings")
    |> create_user_session(params)
  end

  def create(conn, params) do
    create_user_session(conn, params)
  end

  defp create_user_session(conn, %{"user" => user_params}) do
    %{"email" => email, "password" => password} = user_params

    if user = Accounts.get_user_by_email_and_password(email, password) do
      UserAuth.log_in_user(conn, user, user_params)
    else
      # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
      conn
      |> put_flash(:error, gettext("Invalid email or password"))
      |> put_flash(:email, String.slice(email, 0, 160))
      |> redirect(to: ~p"/users/log_in")
    end
  end

  def delete(conn, _params) do
    UserAuth.log_out_user(conn)
  end
end
