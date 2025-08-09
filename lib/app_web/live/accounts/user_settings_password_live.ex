defmodule AppWeb.UserSettingsPasswordLive do
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

      <.form
        for={@form}
        id="password_form"
        phx-change="validate"
        phx-submit="update"
        phx-trigger-action={@trigger_submit}
        action={~p"/users/log_in?_action=password_updated"}
        method="post"
        class="container space-y-2"
      >
        <.input field={@form[:email]} type="hidden" value={@current_user.email} />
        <.input
          field={@form[:password]}
          type="password"
          label={gettext("New password")}
          helper={gettext("Your password must be at least 12 characters long")}
          required
          autocomplete="new-password"
        />
        <.input
          field={@form[:password_confirmation]}
          type="password"
          label={gettext("Confirm new password")}
          helper={gettext("Type your new password again here")}
          required
          autocomplete="new-password"
        />
        <.input
          field={@form[:current_password]}
          name="current_password"
          id="current_password"
          type="password"
          label={gettext("Current password")}
          helper={gettext("Your current password is required to make this change")}
          required
          autocomplete="current-password"
        />

        <.button_group>
          <.button kind={:primary}>
            {gettext("Change password")}
          </.button>
        </.button_group>
      </.form>
    </.app_page>
    """
  end

  def mount(_params, _session, socket) do
    form =
      socket.assigns.current_user
      |> Accounts.change_user_password()
      |> to_form()

    socket =
      assign(socket,
        page_title: gettext("Change password"),
        form: form,
        trigger_submit: false
      )

    {:ok, socket}
  end

  def handle_event("validate", params, socket) do
    %{"current_password" => _password, "user" => user_params} = params

    form =
      socket.assigns.current_user
      |> Accounts.change_user_password(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, form: form)}
  end

  def handle_event("update", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.update_user_password(user, password, user_params) do
      {:ok, user} ->
        form =
          user
          |> Accounts.change_user_password(user_params)
          |> to_form()

        {:noreply, assign(socket, trigger_submit: true, form: form)}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end
