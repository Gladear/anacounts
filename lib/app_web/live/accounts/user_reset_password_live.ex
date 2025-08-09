defmodule AppWeb.UserResetPasswordLive do
  use AppWeb, :live_view

  alias App.Accounts

  def render(assigns) do
    ~H"""
    <.form
      for={@form}
      id="reset_password_form"
      phx-submit="reset_password"
      phx-change="validate"
      class="space-y-2"
    >
      <p>
        {gettext("Please enter a new password for your account")}<br />
        <span class="label">{@user.email}</span>
      </p>

      <.input
        field={@form[:password]}
        type="password"
        label={gettext("New password")}
        class="w-full"
        required
        autocomplete="new-password"
      />

      <.input
        field={@form[:password_confirmation]}
        type="password"
        label={gettext("Confirm new password")}
        class="w-full"
        required
        autocomplete="new-password"
      />

      <.button_group>
        <.button kind={:primary}>
          {gettext("Reset password")}
        </.button>
      </.button_group>
    </.form>

    <div class="text-right">
      {gettext("Not %{email}?", email: @user.email)}
      <.anchor navigate={~p"/users/log_in"}>
        {gettext("Go back to sign in page.")}
      </.anchor>
    </div>
    """
  end

  def mount(params, _session, socket) do
    socket = assign_user_and_token(socket, params)

    form_source =
      case socket.assigns do
        %{user: user} ->
          Accounts.change_user_password(user)

        _ ->
          %{}
      end

    socket =
      socket
      |> assign(page_title: gettext("Reset your password"))
      |> assign_form(form_source)

    {:ok, socket, temporary_assigns: [form: nil]}
  end

  # Do not log in the user after reset password to avoid a
  # leaked token giving the user access to the account.
  def handle_event("reset_password", %{"user" => user_params}, socket) do
    case Accounts.reset_user_password(socket.assigns.user, user_params) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Password reset."))
         |> redirect(to: ~p"/users/log_in")}

      {:error, changeset} ->
        changeset = Map.put(changeset, :action, :insert)
        {:noreply, assign_form(socket, changeset)}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset =
      socket.assigns.user
      |> Accounts.change_user_password(user_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  defp assign_user_and_token(socket, %{"token" => token}) do
    if user = Accounts.get_user_by_reset_password_token(token) do
      assign(socket, user: user, token: token)
    else
      socket
      |> put_flash(:error, gettext("Reset password link is invalid or it has expired."))
      |> redirect(to: ~p"/")
    end
  end

  defp assign_form(socket, source) do
    assign(socket, :form, to_form(source, as: "user"))
  end
end
