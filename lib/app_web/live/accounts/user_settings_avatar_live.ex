defmodule AppWeb.UserSettingsAvatarLive do
  use AppWeb, :live_view

  def render(assigns) do
    ~H"""
    <.app_page>
      <:breadcrumb>
        <.breadcrumb_item navigate={~p"/users/settings"}>
          {gettext("My account")}
        </.breadcrumb_item>
        <.breadcrumb_item>
          {@page_title}
        </.breadcrumb_item>
      </:breadcrumb>
      <:title>{@page_title}</:title>

      <div class="container space-y-2">
        <p>
          {gettext("Anacounts uses Gravatar to display user avatars.")}
          {gettext("Gravatar is a service providing globally unique avatars.")}
        </p>
        <p>{gettext("To edit your avatar, create an account and personalize your Gravatar.")}</p>

        <div class="text-right">
          <.anchor href="https://en.gravatar.com/" target="_blank" rel="noreferrer">
            {gettext("Go to Gravatar")}
          </.anchor>
        </div>
      </div>
    </.app_page>
    """
  end

  def mount(_params, _session, socket) do
    socket = assign(socket, :page_title, gettext("Change avatar"))

    {:ok, socket}
  end
end
