defmodule AppWeb.UserSettingsLive do
  use AppWeb, :live_view

  import AppWeb.AccountsComponents

  def render(assigns) do
    ~H"""
    <.app_page>
      <:breadcrumb>
        <.breadcrumb_item>
          {@page_title}
        </.breadcrumb_item>
      </:breadcrumb>
      <:title>{@page_title}</:title>

      <.hero_avatar user={@current_user} alt={gettext("Your avatar")} />

      <.card_grid>
        <.link navigate={~p"/users/settings/email"}>
          <.card_button icon={:envelope}>{gettext("Change email")}</.card_button>
        </.link>
        <.link navigate={~p"/users/settings/avatar"}>
          <.card_button icon={:user_circle}>{gettext("Change avatar")}</.card_button>
        </.link>
        <.link navigate={~p"/users/settings/password"}>
          <.card_button icon={:lock_closed}>{gettext("Change password")}</.card_button>
        </.link>
        <.link href={~p"/users/log_out"} method="delete">
          <.card_button icon={:arrow_left_start_on_rectangle}>
            {gettext("Disconnect")}
          </.card_button>
        </.link>
      </.card_grid>
    </.app_page>
    """
  end

  def mount(_params, _session, socket) do
    socket = assign(socket, :page_title, gettext("My account"))
    {:ok, socket}
  end
end
