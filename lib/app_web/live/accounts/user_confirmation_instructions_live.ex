defmodule AppWeb.UserConfirmationInstructionsLive do
  use AppWeb, :live_view

  alias App.Accounts

  def render(assigns) do
    ~H"""
    <p class="mb-4">
      {gettext(
        "Confirmation instructions were sent when you created your account." <>
          " If you did not receive them, check out your spam, or send the instructions again."
      )}
    </p>

    <p>
      {gettext("Send confirmation instructions for your account")}<br />
      <span class="label">{@current_user.email}</span>
    </p>

    <.button_group>
      <.button kind={:primary} phx-click="send_instructions">
        {gettext("Send instructions")}
      </.button>
    </.button_group>
    """
  end

  def mount(_params, _session, socket) do
    socket = assign(socket, page_title: gettext("Confirm your account"))

    {:ok, socket}
  end

  def handle_event("send_instructions", _params, socket) do
    Accounts.deliver_user_confirmation_instructions(
      socket.assigns.current_user,
      &url(~p"/users/confirm/#{&1}")
    )

    socket =
      socket
      |> put_flash(
        :info,
        gettext(
          "If your email has not been confirmed yet," <>
            " you will receive an email with instructions shortly."
        )
      )
      |> redirect(to: ~p"/users/settings")

    {:noreply, socket}
  end
end
