defmodule AppWeb.UserForgotPasswordLive do
  @moduledoc """
  Let users request a password reset from an administrator.

  The user inputs their email address, and a link to the administrator
  reset password page, prefilled with that email, is displayed so the user
  can send it to an administrator.
  """

  use AppWeb, :live_view

  def render(%{admin_reset_password_url: nil} = assigns) do
    ~H"""
    <.form for={@form} id="reset_password_form" phx-submit="generate" class="space-y-2">
      <p>
        {gettext(
          "Enter your user account's email address and we will give you a link to send to an administrator, so they can reset your password."
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
          {gettext("Get the link")}
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

  def render(assigns) do
    ~H"""
    <div class="space-y-2">
      <p>
        {gettext("Send this link to an administrator so they can reset your password.")}
      </p>

      <.input
        type="text"
        name="admin_reset_password_url"
        value={@admin_reset_password_url}
        readonly
        phx-click={
          JS.dispatch("app:copy-to-clipboard")
          |> JS.show(to: "#copied-to-clipboard")
        }
      />
      <p id="copied-to-clipboard" class="hidden">
        {gettext("Copied to clipboard !")}
      </p>
    </div>

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
        admin_reset_password_url: nil,
        page_title: gettext("Forgot your password?")
      )

    {:ok, socket}
  end

  def handle_event("generate", %{"user" => %{"email" => email}}, socket) do
    admin_reset_password_url = url(~p"/admin/users/reset_password?email=#{email}")
    {:noreply, assign(socket, :admin_reset_password_url, admin_reset_password_url)}
  end
end
