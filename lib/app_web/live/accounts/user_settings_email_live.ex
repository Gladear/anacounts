defmodule AppWeb.UserSettingsEmailLive do
  use AppWeb, :live_view

  alias App.Accounts

  def render(assigns) do
    ~H"""
    <.app_page flash={@flash}>
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
        id="email_form"
        phx-change="validate"
        phx-submit="update"
        class="container space-y-2"
      >
        <.input
          field={@form[:email]}
          type="email"
          label={gettext("New email")}
          required
          autocomplete="username"
          phx-debounce
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
          phx-debounce="blur"
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

    case Accounts.update_user_email(user, password, user_params) do
      {:ok, _user} ->
        socket =
          socket
          |> put_flash(:info, gettext("Email changed successfully."))
          |> push_navigate(to: ~p"/users/settings")

        {:noreply, socket}

      {:error, changeset} ->
        form =
          changeset
          |> Map.put(:action, :insert)
          |> to_form()

        {:noreply, assign(socket, :form, form)}
    end
  end
end
