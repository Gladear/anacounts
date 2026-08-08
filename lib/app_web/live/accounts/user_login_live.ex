defmodule AppWeb.UserLoginLive do
  use AppWeb, :live_view

  alias App.Accounts.Webauthn
  alias AppWeb.UserAuth

  require Logger

  def render(assigns) do
    ~H"""
    <.form for={@form} id="login_form" action={~p"/users/log_in"} class="space-y-2">
      <.input
        field={@form[:email]}
        type="email"
        label={gettext("Email")}
        required
        autocomplete="username webauthn"
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
        <.button kind={:secondary} type="button" phx-click="passkey_start_authentication">
          {gettext("Sign in with a passkey")}
        </.button>
      </.button_group>
    </.form>

    <.form
      for={to_form(%{}, as: :passkey)}
      id="passkey_login_form"
      action={~p"/users/log_in"}
      method="post"
      phx-trigger-action={@trigger_passkey_login}
      phx-hook=".PasskeyAuthentication"
      class="hidden"
    >
      <input type="hidden" name="_action" value="passkey_auth" />
      <input type="hidden" name="passkey_token" value={@passkey_login_token} />
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

    <script :type={Phoenix.LiveView.ColocatedHook} name=".PasskeyAuthentication">
      import { startAuthentication } from "@simplewebauthn/browser";

      export default {
        mounted() {
          this.handleEvent("passkey:conditional_authenticate", ({ options }) => {
            try {
              this.authenticate(options);
            } catch (_error) {
              // Autofill prompt, started on mount; silently ignored if the user
              // dismisses it or picks no credential, since it isn't an explicit
              // request.
            }
          });

          // Explicit "Sign in with a passkey" button.
          this.handleEvent("passkey:authenticate", ({ options }) => {
            try {
              this.authenticate(options);
            } catch (error) {
              this.pushEvent("passkey:authenticate_error", {
                message: error.message,
              });
            }
          });
        },

        async authenticate(optionsJSON) {
          this.abortController?.abort();
          this.abortController = new AbortController();

          const response = await startAuthentication({
            optionsJSON,
            signal: this.abortController.signal,
          });
          this.pushEvent("passkey:authenticate_response", { response });
        },

        destroyed() {
          this.abortController?.abort();
        },
      };
    </script>
    """
  end

  def mount(_params, _session, socket) do
    email = Phoenix.Flash.get(socket.assigns.flash, :email)
    form = to_form(%{"email" => email}, as: "user")

    socket =
      socket
      |> assign(
        form: form,
        page_title: gettext("Sign in to your account")
      )
      |> init_passkey_login_token()
      |> maybe_begin_conditional_passkey_authentication()

    {:ok, socket, temporary_assigns: [form: form]}
  end

  # Only start once connected: the challenge is single-use and tied to this
  # process, so generating it during the (discarded) static render would
  # waste it.
  defp maybe_begin_conditional_passkey_authentication(socket) do
    if connected?(socket) do
      begin_passkey_authentication(socket, "passkey:conditional_authenticate")
    else
      assign(socket, :passkey_challenge, nil)
    end
  end

  def handle_event("passkey_start_authentication", _params, socket) do
    {:noreply, begin_passkey_authentication(socket, "passkey:authenticate")}
  end

  def handle_event("passkey:authenticate_response", %{"response" => credential}, socket) do
    case Webauthn.verify_passkey_authentication(credential, socket.assigns.passkey_challenge) do
      {:ok, user} ->
        token = UserAuth.sign_passkey_login_token(user)
        {:noreply, login_with_passkey_token(socket, token)}

      {:error, reason} ->
        maybe_log_authentication_failure(reason)

        socket =
          socket
          |> put_flash(:error, gettext("Passkey sign-in failed, please try again."))
          |> maybe_begin_conditional_passkey_authentication()

        {:noreply, socket}
    end
  end

  def handle_event("passkey:authenticate_error", %{"message" => message}, socket) do
    {:noreply, put_flash(socket, :error, message)}
  end

  defp begin_passkey_authentication(socket, event) do
    {challenge, options} = Webauthn.begin_passkey_authentication()

    socket
    |> assign(:passkey_challenge, challenge)
    |> push_event(event, %{options: options})
  end

  defp init_passkey_login_token(socket) do
    assign(socket, trigger_passkey_login: false, passkey_login_token: nil)
  end

  defp login_with_passkey_token(socket, token) do
    assign(socket, trigger_passkey_login: true, passkey_login_token: token)
  end

  defp maybe_log_authentication_failure(:invalid_credential), do: :ok
  defp maybe_log_authentication_failure(:not_found), do: :ok

  defp maybe_log_authentication_failure(reason) do
    Logger.error("An error occured while verifying passkey authentication: #{inspect(reason)}")
  end
end
