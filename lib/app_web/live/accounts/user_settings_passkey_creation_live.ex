defmodule AppWeb.UserSettingsPasskeyCreationLive do
  @moduledoc """
  The live view to register a new passkey for the current device.
  """
  use AppWeb, :live_view

  alias App.Accounts.Webauthn
  alias AppWeb.PasskeyRegistrationFlow

  def render(assigns) do
    ~H"""
    <.app_page flash={@flash} current_user={@current_user}>
      <:breadcrumb>
        <.breadcrumb_item navigate={~p"/users/settings"}>
          {gettext("My account")}
        </.breadcrumb_item>
        <.breadcrumb_item navigate={~p"/users/settings/passkeys"}>
          {gettext("Registered passkeys")}
        </.breadcrumb_item>
        <.breadcrumb_item>
          {@page_title}
        </.breadcrumb_item>
      </:breadcrumb>
      <:title>{@page_title}</:title>

      <section class="space-y-3">
        <div
          :if={@step == :intro}
          class="space-y-3"
          id="passkey-registration-hook"
          phx-hook=".PasskeyRegistration"
        >
          <p class="paragraph mt-2 mb-8">
            {gettext(
              "A passkey lets you sign in using your device's built-in security" <>
                " (fingerprint, face recognition, or screen lock) instead of a password." <>
                " It is stored securely on this device and can't be phished or leaked."
            )}
          </p>

          <.button_group>
            <.button kind={:primary} phx-click="start_register">
              {gettext("Add passkey")}
            </.button>
            <.anchor navigate={~p"/users/settings/passkeys"}>
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
      </section>

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
    </.app_page>
    """
  end

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, gettext("Add a passkey"))
      |> PasskeyRegistrationFlow.assign_intro()

    {:ok, socket}
  end

  def handle_event("start_register", _params, socket) do
    user = socket.assigns.current_user
    {challenge, options} = Webauthn.begin_passkey_registration(user)

    socket =
      socket
      |> assign(:challenge, challenge)
      |> push_event("register", %{options: options})

    {:noreply, socket}
  end

  def handle_event("register_response", %{"response" => credential}, socket) do
    socket =
      PasskeyRegistrationFlow.handle_register_response(
        socket,
        socket.assigns.current_user,
        credential
      )

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
        socket = push_navigate(socket, to: ~p"/users/settings/passkeys")

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        socket = assign(socket, :form, to_form(changeset))
        {:noreply, socket}
    end
  end
end
