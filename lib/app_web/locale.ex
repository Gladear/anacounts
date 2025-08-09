defmodule AppWeb.Locale do
  @moduledoc """
  This module is used to handle, fetch, set the locale in the session.

  It can be used as an `on_mount` hook for LiveViews to set their locale
  based on the session.
  """

  @doc false
  def on_mount(:default, _params, session, socket) do
    {:ok, _locale} = Cldr.Plug.put_locale_from_session(session)
    {:cont, socket}
  end
end
