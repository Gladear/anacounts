defmodule AppWeb.PageComponents do
  @moduledoc """
  A module defining complex components for live views.

  The components defined here are based on the components defined in
  `AppWeb.CoreComponents`. They are more complex and usually only fit
  in more specific contexts.
  """

  use AppWeb, :gettext
  use AppWeb, :verified_routes
  use Phoenix.Component

  import AppWeb.CoreComponents

  alias App.Accounts
  alias App.Accounts.User

  ## App page

  @doc """
  The app page contains part of the layout of most pages of the application.

  It includes the breadcrumb, title, and the main content of the page.
  """

  attr :flash, :map, required: true, doc: "The @flash assign"
  attr :current_user, User, required: true

  slot :breadcrumb, required: true
  slot :title, required: true

  def app_page(assigns) do
    ~H"""
    <div class="app-page">
      <.user_passkey_banner current_user={@current_user} />
      <header>
        <.breadcrumb>
          <.breadcrumb_home navigate={~p"/books"} alt={gettext("Home")} />
          {render_slot(@breadcrumb)}
        </.breadcrumb>
        <h1 class="title-1 truncate">{render_slot(@title)}</h1>
      </header>
      <main>
        <.alert_flash :for={kind <- [:info, :error]} flash={@flash} kind={kind} class="mb-4" />
        {render_slot(@inner_block)}
      </main>
    </div>
    """
  end

  ## User passkey banner

  @doc """
  Warns the user that passkey-only sign-in is coming, and prompts them to register a
  passkey if they haven't got one yet.

  Hides itself once the user has registered at least one passkey.
  """
  attr :current_user, User, required: true

  def user_passkey_banner(assigns) do
    ~H"""
    <.alert :if={not Accounts.user_has_passkey?(@current_user)} kind={:warning} class="mb-4">
      <div>
        {gettext(
          "Soon, you will only be able to sign in with a passkey. Register one now so you don't lose access to your account."
        )}
        <br />
        <.anchor navigate={~p"/users/settings/passkeys/new"}>
          {gettext("Register a passkey")}
        </.anchor>
      </div>
    </.alert>
    """
  end
end
