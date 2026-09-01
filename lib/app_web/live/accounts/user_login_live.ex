defmodule AppWeb.UserLoginLive do
  use AppWeb, :live_view

  def render(assigns) do
    ~H"""
    <.form for={@form} id="login_form" action={~p"/users/log_in"} class="space-y-2">
      <.input
        field={@form[:email]}
        type="email"
        label={gettext("Email")}
        required
        autocomplete="email"
      />

      <.input
        field={@form[:password]}
        type="password"
        label={gettext("Password")}
        required
        autocomplete="current-password"
      />

      <div class="flex flex-col sm:flex-row sm:items-center justify-between">
        <.input field={@form[:remember_me]} type="checkbox" label={gettext("Keep me logged in")} />

        <.anchor navigate={~p"/users/reset_password"}>
          {gettext("Forgot your password?")}
        </.anchor>
      </div>

      <.button_group>
        <.button kind={:primary}>
          {gettext("Sign in")}
        </.button>
      </.button_group>
    </.form>

    <.divider class="my-4" />

    <h2 class="title-2">{gettext("Create an account")}</h2>

    <p class="mb-4">
      {gettext(
        "Anacounts is a free and open-source software that helps you share expensenses" <>
          " for a trip with your friend or in your household in a more fair way."
      )}
    </p>

    <.button_group>
      <.button kind={:secondary} navigate={~p"/users/register"}>
        <.icon name={:envelope} />
        {gettext("Create an account")}
      </.button>
    </.button_group>
    """
  end

  def mount(_params, _session, socket) do
    email = Phoenix.Flash.get(socket.assigns.flash, :email)
    form = to_form(%{"email" => email}, as: "user")

    socket =
      assign(socket,
        form: form,
        page_title: gettext("Sign in to your account")
      )

    {:ok, socket, temporary_assigns: [form: form]}
  end
end
