defmodule AppWeb.UserSettingsDeviceLinkLive do
  @moduledoc """
  The live view to add a new device: shows a short-lived, single-use link
  (and its QR code) that lets another device register a passkey for the
  current user.
  """
  use AppWeb, :live_view

  alias App.Accounts

  def render(assigns) do
    ~H"""
    <.app_page flash={@flash}>
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
        <p class="paragraph mt-2 mb-8">
          {gettext(
            "Scan this QR code with your new device, or copy the link below and open it there." <>
              " It will invite that device to register its own passkey, and sign you in" <>
              " automatically. This link expires in 10 minutes."
          )}
        </p>

        <div class="flex justify-center">
          {raw(@device_link_qr_code)}
        </div>

        <.input
          type="text"
          name="device_link_url"
          value={@device_link_url}
          readonly
          phx-click={
            JS.dispatch("app:copy-to-clipboard")
            |> JS.hide(to: "#copy-to-clipboard-helper")
            |> JS.show(to: "#copied-to-clipboard")
          }
        />
        <p id="copy-to-clipboard-helper">
          {gettext("Paste this link on your other device to register it")}
        </p>
        <p id="copied-to-clipboard" class="hidden">
          {gettext("Copied to clipboard !")}
        </p>

        <.button_group>
          <.anchor navigate={~p"/users/settings/passkeys"}>
            {gettext("Cancel")}
          </.anchor>
        </.button_group>
      </section>
    </.app_page>
    """
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    token = Accounts.create_device_link_token(user)
    device_link_url = url(~p"/devices/link/#{token}")

    socket =
      assign(socket,
        page_title: gettext("Add a new device"),
        device_link_url: device_link_url,
        device_link_qr_code: EQRCode.encode(device_link_url) |> EQRCode.svg(width: 240)
      )

    {:ok, socket}
  end
end
