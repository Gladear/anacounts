defmodule AppWeb.PasskeyRegistrationFlow do
  @moduledoc """
  Shared step-machine assigns for LiveViews driving passkey registration:
  the WebAuthn ceremony, then naming the new passkey.

  Used by both `AppWeb.UserSettingsPasskeyCreationLive` (registering a
  passkey for the current device) and `AppWeb.DeviceLinkLive` (registering
  a passkey for a new device via a device-link token).
  """

  use AppWeb, :gettext

  import Phoenix.Component, only: [assign: 2, assign: 3, to_form: 1]
  import Phoenix.LiveView, only: [put_flash: 3]

  alias App.Accounts.UserPasskey
  alias App.Accounts.Webauthn

  @doc """
  Resets the socket to the initial (`:intro`) step.
  """
  def assign_intro(socket) do
    assign(socket, step: :intro, form: nil, challenge: nil, pending_passkey: nil)
  end

  @doc """
  Verifies a WebAuthn registration response for `user`, moving the socket
  to the `:naming` step on success.
  """
  def handle_register_response(socket, user, credential) do
    case Webauthn.verify_passkey_registration(user, credential, socket.assigns.challenge) do
      {:ok, passkey} ->
        form = %UserPasskey{} |> UserPasskey.device_name_changeset(%{}) |> to_form()
        assign(socket, step: :naming, pending_passkey: passkey, form: form)

      {:error, _reason} ->
        socket
        |> put_flash(:error, gettext("Registration failed, please try again."))
        |> assign_intro()
    end
  end

  @doc """
  Validates the device name form for the passkey being named.
  """
  def handle_validate(socket, passkey_attrs) do
    form =
      %UserPasskey{}
      |> UserPasskey.device_name_changeset(passkey_attrs)
      |> Map.put(:action, :validate)
      |> to_form()

    assign(socket, :form, form)
  end
end
