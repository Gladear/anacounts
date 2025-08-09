defmodule AppWeb.UserRegistrationLive do
  use AppWeb, :live_view

  alias App.Accounts
  alias App.Accounts.User

  def render(assigns) do
    ~H"""
    <.form
      for={@form}
      id="registration_form"
      phx-submit="save"
      phx-change="validate"
      phx-trigger-action={@trigger_submit}
      action={~p"/users/log_in?_action=registered"}
      method="post"
      class="space-y-2"
    >
      <.input
        field={@form[:email]}
        type="email"
        label={gettext("Email")}
        helper={gettext("This email will be your identifier")}
        required
        phx-debounce
        autocomplete="email"
      />

      <.input
        field={@form[:password]}
        type="password"
        label={gettext("Password")}
        pattern=".{12,}"
        helper={gettext("Your password must be at least 12 characters long")}
        required
        phx-debounce
        autocomplete="new-password"
      />

      <.button_group>
        <.button kind={:primary}>
          {gettext("Register")}
        </.button>
      </.button_group>
    </.form>

    <div class="text-right">
      {gettext("Already have an account?")}
      <.anchor navigate={~p"/users/log_in"}>
        {gettext("Log in here.")}
      </.anchor>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    changeset = Accounts.change_user_registration(%User{})

    socket =
      socket
      |> assign(trigger_submit: false)
      |> assign(page_title: gettext("Create an account"))
      |> assign_form(changeset)

    {:ok, socket, temporary_assigns: [form: nil]}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        {:ok, _} =
          Accounts.deliver_user_confirmation_instructions(
            user,
            &url(~p"/users/confirm/#{&1}")
          )

        changeset = Accounts.change_user_registration(user)
        socket = socket |> assign(trigger_submit: true) |> assign_form(changeset)
        {:noreply, socket}

      {:error, changeset} ->
        socket = assign_form(socket, changeset)
        {:noreply, socket}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset =
      %User{}
      |> Accounts.change_user_registration(user_params)
      |> Map.put(:action, :validate)

    socket = assign_form(socket, changeset)
    {:noreply, socket}
  end

  defp assign_form(socket, changeset) do
    form = to_form(changeset, as: "user")
    assign(socket, form: form)
  end
end
