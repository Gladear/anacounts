defmodule AppWeb.AdminUserResetPasswordLive do
  @moduledoc """
  Let administrators reset the password of any user.

  The administrator inputs the email of the target user. A reset password token
  is then generated, and the reset password URL is displayed so the administrator
  can send it to the user. The email input can be autofilled using the `email`
  query parameter.
  """

  use AppWeb, :live_view

  alias App.Accounts

  def render(%{reset_password_url: nil} = assigns) do
    ~H"""
    <.form for={@form} id="admin_reset_password_form" phx-submit="generate" class="space-y-2">
      <p>
        {gettext("Enter the email address of the user whose password must be reset.")}
      </p>

      <.input field={@form[:email]} type="email" label={gettext("Email")} required />

      <.button_group>
        <.button kind={:primary}>
          {gettext("Generate reset link")}
        </.button>
      </.button_group>
    </.form>
    """
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-2">
      <p>
        {gettext(
          "Send this link to %{email} so they can reset their password. It is valid for 1 day.",
          email: @user.email
        )}
      </p>

      <input
        id="reset_password_url"
        type="text"
        value={@reset_password_url}
        readonly
        class="w-full font-mono text-sm"
        onclick="this.select()"
      />

      <div class="text-right">
        <.anchor patch={~p"/admin/users/reset_password"}>
          {gettext("Reset another password")}
        </.anchor>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, :page_title, gettext("Reset a user's password"))}
  end

  def handle_params(params, _uri, socket) do
    socket =
      assign(socket,
        form: to_form(%{"email" => params["email"] || ""}, as: :user),
        user: nil,
        reset_password_url: nil
      )

    {:noreply, socket}
  end

  def handle_event("generate", %{"user" => %{"email" => email} = user_params}, socket) do
    if user = Accounts.get_user_by_email(email) do
      token = Accounts.generate_user_reset_password_token(user)

      socket =
        socket
        |> clear_flash()
        |> assign(user: user, reset_password_url: url(~p"/users/reset_password/#{token}"))

      {:noreply, socket}
    else
      socket =
        socket
        |> put_flash(:error, gettext("No user found with this email"))
        |> assign(form: to_form(user_params, as: :user))

      {:noreply, socket}
    end
  end
end
