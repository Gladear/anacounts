defmodule AppWeb.UserForgotPasswordLive do
  use AppWeb, :live_view

  alias App.Accounts

  def render(assigns) do
    ~H"""
    <.form for={@form} id="reset_password_form" phx-submit="send_email" class="space-y-2">
      <p>
        {gettext(
          "Enter your user account's email address and we will send you a password reset link."
        )}
      </p>

      <.input
        field={@form[:email]}
        type="email"
        label={gettext("Email")}
        autocomplete="email"
        required
      />

      <.button_group>
        <.button kind={:primary}>
          {gettext("Send instructions")}
        </.button>
      </.button_group>
    </.form>

    <div class="text-right">
      <.anchor navigate={~p"/users/log_in"}>
        {gettext("Sign in to your account")}
      </.anchor>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    socket =
      assign(socket,
        form: to_form(%{}, as: "user"),
        page_title: gettext("Forgot your password?")
      )

    {:ok, socket, temporary_assigns: [form: nil]}
  end

  def handle_event("send_email", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_user_reset_password_instructions(
        user,
        &url(~p"/users/reset_password/#{&1}")
      )
    end

    info =
      gettext(
        "If your email is in our system, you will receive instructions" <>
          " to reset your password shortly."
      )

    socket =
      socket
      |> put_flash(:info, info)
      |> redirect(to: ~p"/users/log_in")

    {:noreply, socket}
  end
end
