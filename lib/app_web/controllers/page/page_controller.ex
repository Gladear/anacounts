defmodule AppWeb.PageController do
  use AppWeb, :controller

  def index(conn, _params) do
    if conn.assigns[:current_user] do
      redirect(conn, to: ~p"/books")
    else
      redirect(conn, to: ~p"/users/log_in")
    end
  end
end
