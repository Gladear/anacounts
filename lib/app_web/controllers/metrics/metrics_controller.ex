defmodule AppWeb.MetricsController do
  @moduledoc """
  Get metrics regarding the application.
  """

  use AppWeb, :controller

  def health_check(conn, _opts) do
    text(conn, "OK")
  end
end
