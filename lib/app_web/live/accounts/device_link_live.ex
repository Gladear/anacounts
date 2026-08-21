defmodule AppWeb.DeviceLinkLive do
  @moduledoc """
  The live view to register a new passkey for the current device, reached
  by following a link (or scanning a QR code) generated from another,
  already-authenticated device. On success, this device is signed in.
  """
  use AppWeb, :live_view

  alias App.Accounts
  alias App.Accounts.Webauthn
  alias AppWeb.PasskeyRegistrationFlow
  alias AppWeb.UserAuth

  def render(assigns) do
    ~H"""
    <p class="paragraph mt-2 mb-8">
      {gettext(
        "You're about to register this device on your account. " <>
          "This will trigger the registration of a new passkey, " <>
          "then you'll be signed in automatically once it's registered."
      )}
    </p>

    <div
      :if={@step == :intro}
      class="space-y-3"
      id="passkey-registration-hook"
      phx-hook=".PasskeyRegistration"
    >
      <.button_group>
        <.button kind={:primary} phx-click="start_register">
          {gettext("Add passkey")}
        </.button>
        <.anchor navigate={~p"/"}>
          {gettext("Cancel")}
        </.anchor>
      </.button_group>
    </div>

    <.form
      :if={@step == :naming}
      id="passkey-registration-form"
      for={@form}
      phx-change="validate"
      phx-submit="save"
      class="space-y-2"
    >
      <.input
        field={@form[:device_name]}
        type="text"
        label={gettext("Device name")}
        helper={gettext("A name to identify this device")}
        phx-debounce
        required
      />
      <.button_group>
        <.button kind={:primary}>
          {gettext("Save")}
        </.button>
      </.button_group>
    </.form>

    <.form
      for={to_form(%{}, as: :passkey)}
      id="device_link_login_form"
      action={~p"/users/log_in"}
      method="post"
      phx-trigger-action={@trigger_passkey_login}
      class="hidden"
    >
      <input type="hidden" name="_action" value="passkey_auth" />
      <input type="hidden" name="passkey_token" value={@passkey_login_token} />
    </.form>

    <script :type={Phoenix.LiveView.ColocatedHook} name=".PasskeyRegistration">
      import { startRegistration } from "@simplewebauthn/browser";

      export default {
        mounted() {
          this.handleEvent("register", async ({ options }) => {
            try {
              const response = await startRegistration({ optionsJSON: options });
              this.pushEvent("register_response", { response });
            } catch (error) {
              this.pushEvent("register_error", { message: error.message });
            }
          });
        },
      };
    </script>
    """
  end

  def mount(%{"token" => token}, _session, socket) do
    case Accounts.get_user_by_device_link_token(token) do
      nil ->
        socket =
          socket
          |> put_flash(:error, gettext("This link is invalid or has expired."))
          |> redirect(to: ~p"/")

        {:ok, socket}

      user ->
        socket =
          socket
          |> assign(page_title: gettext("Add a new device"), user: user)
          |> PasskeyRegistrationFlow.assign_intro()
          |> init_passkey_login_token()

        {:ok, socket}
    end
  end

  defp init_passkey_login_token(socket) do
    assign(socket, trigger_passkey_login: false, passkey_login_token: nil)
  end

  defp login_with_passkey_token(socket, token) do
    assign(socket, trigger_passkey_login: true, passkey_login_token: token)
  end

  def handle_event("start_register", _params, socket) do
    user = socket.assigns.user
    {challenge, options} = Webauthn.begin_passkey_registration(user)

    socket =
      socket
      |> assign(:challenge, challenge)
      |> push_event("register", %{options: options})

    {:noreply, socket}
  end

  def handle_event("register_response", %{"response" => credential}, socket) do
    socket =
      PasskeyRegistrationFlow.handle_register_response(socket, socket.assigns.user, credential)

    {:noreply, socket}
  end

  def handle_event("register_error", %{"message" => message}, socket) do
    {:noreply, put_flash(socket, :error, message)}
  end

  def handle_event("validate", %{"user_passkey" => passkey_attrs}, socket) do
    {:noreply, PasskeyRegistrationFlow.handle_validate(socket, passkey_attrs)}
  end

  def handle_event("save", %{"user_passkey" => passkey_attrs}, socket) do
    case Webauthn.register_passkey(socket.assigns.pending_passkey, passkey_attrs) do
      {:ok, _passkey} ->
        user = socket.assigns.user
        Accounts.delete_device_link_tokens(user)
        token = UserAuth.sign_passkey_login_token(user)

        {:noreply, login_with_passkey_token(socket, token)}

      {:error, %Ecto.Changeset{} = changeset} ->
        socket = assign(socket, :form, to_form(changeset))
        {:noreply, socket}
    end
  end
end
