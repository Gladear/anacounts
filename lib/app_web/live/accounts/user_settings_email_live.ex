defmodule AppWeb.UserSettingsEmailLive do
  use AppWeb, :live_view

  alias App.Accounts

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

      <.alert_flash flash={@flash} kind={:info} class="mb-4" />
      <.alert_flash flash={@flash} kind={:error} class="mb-4" />

      <.form
        for={@form}
        id="email_form"
        phx-change="validate"
        phx-submit="update"
        class="container space-y-2"
      >
        <p>
          {gettext(
            "Before making the change effective, a confirmation" <>
              " email will be sent to the new address."
          )}
        </p>

        <.input
          field={@form[:email]}
          type="email"
          label={gettext("New email")}
          helper={gettext("The confirmation email will be sent to this address")}
          required
          autocomplete="username"
        />

        <.input
          field={@form[:current_password]}
          name="current_password"
          id="current_password_for_email"
          type="password"
          label={gettext("Password")}
          helper={gettext("Your current password is required to make this change")}
          required
          autocomplete="current-password"
        />

        <.button_group>
          <.button kind={:primary}>
            {gettext("Change email")}
          </.button>
        </.button_group>
      </.form>
    </.app_page>
    """
  end

  def mount(%{"token" => token}, _session, socket) do
    socket =
      case Accounts.update_user_email(socket.assigns.current_user, token) do
        :ok ->
          push_navigate(socket, to: ~p"/users/settings")

        :error ->
          error =
            gettext("Email change link is invalid or it has expired. You can create a new one.")

          socket
          |> put_flash(:error, error)
          |> push_navigate(to: ~p"/users/settings/email")
      end

    {:ok, socket}
  end

  def mount(_params, _session, socket) do
    email_changeset = Accounts.change_user_email(socket.assigns.current_user)

    socket =
      assign(socket,
        page_title: gettext("Change email"),
        form: to_form(email_changeset)
      )

    {:ok, socket}
  end

  def handle_event("validate", params, socket) do
    %{"current_password" => _password, "user" => user_params} = params

    form =
      socket.assigns.current_user
      |> Accounts.change_user_email(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, form: form)}
  end

  def handle_event("update", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.apply_user_email(user, password, user_params) do
      {:ok, applied_user} ->
        Accounts.deliver_user_update_email_instructions(
          applied_user,
          user.email,
          &url(~p"/users/settings/email/confirm/#{&1}")
        )

        info = gettext("A link to confirm your email change has been sent to the new address.")
        {:noreply, put_flash(socket, :info, info)}

      {:error, changeset} ->
        form =
          changeset
          |> Map.put(:action, :insert)
          |> to_form()

        {:noreply, assign(socket, :form, form)}
    end
  end
end
