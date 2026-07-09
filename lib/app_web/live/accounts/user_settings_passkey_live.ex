defmodule AppWeb.UserSettingsPasskeysLive do
  use AppWeb, :live_view

  alias App.Accounts
  alias App.Accounts.UserPasskey

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

      <section class="space-y-3">
        <ul
          id="passkeys"
          phx-update="stream"
          class="grid grid-cols-[1fr,6rem,6rem] gap-y-2 gap-x-4 auto-rows-fr"
        >
          <li id="passkeys-empty" class="label hidden only:block">
            {gettext("No passkeys registered yet.")}
          </li>
          <li
            :for={{dom_id, passkey} <- @streams.passkeys}
            id={dom_id}
            class="grid grid-cols-subgrid col-span-full items-end"
          >
            <%= if @renaming != nil and @renaming.id == passkey.id do %>
              <.form
                id="rename-passkey-form"
                for={@rename_form}
                phx-change="validate_rename"
                phx-submit="submit_rename"
                class="contents"
              >
                <.input field={@rename_form[:device_name]} phx-debounce />
                <.button kind={:primary}>{gettext("Save")}</.button>
                <.button kind={:secondary} type="button" phx-click="cancel_rename">
                  {gettext("Cancel")}
                </.button>
              </.form>
            <% else %>
              <div>
                <p class="label">{passkey.device_name}</p>
                <p class="text-sm">
                  {gettext("Added on %{date}", date: Localize.Date.to_string!(passkey.inserted_at))}
                </p>
              </div>

              <.button
                kind={:secondary}
                phx-click="begin_rename"
                phx-value-id={passkey.id}
              >
                {gettext("Rename")}
              </.button>

              <.button
                kind={:secondary}
                phx-click="delete"
                phx-value-id={passkey.id}
                data-confirm={gettext("Delete this passkey?")}
              >
                {gettext("Delete")}
              </.button>
            <% end %>
          </li>
        </ul>
      </section>
    </.app_page>
    """
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user

    socket =
      socket
      |> assign(
        page_title: gettext("Registered passkeys"),
        renaming: nil,
        rename_form: nil
      )
      |> stream_async(:passkeys, fn -> {:ok, Accounts.list_user_passkeys(user)} end)

    {:ok, socket}
  end

  # --- Renaming ---

  def handle_event("begin_rename", %{"id" => id}, socket) do
    user = socket.assigns.current_user
    passkey = Accounts.get_user_passkey!(user, id)

    socket =
      socket
      |> assign(
        renaming: passkey,
        rename_form: passkey |> UserPasskey.device_name_changeset(%{}) |> to_form(as: "rename")
      )
      |> stream_insert(:passkeys, passkey)

    {:noreply, socket}
  end

  def handle_event("validate_rename", %{"rename" => passkey_attrs}, socket) do
    passkey = socket.assigns.renaming

    rename_form =
      passkey
      |> UserPasskey.device_name_changeset(passkey_attrs)
      |> Map.put(:action, :validate)
      |> to_form(as: "rename")

    socket =
      socket
      |> assign(:rename_form, rename_form)
      # Force re-render the passkey line
      |> stream_insert(:passkeys, passkey)

    {:noreply, socket}
  end

  def handle_event("submit_rename", %{"rename" => passkey_attrs}, socket) do
    passkey = socket.assigns.renaming

    case Accounts.rename_user_passkey(passkey, passkey_attrs) do
      {:ok, passkey} ->
        socket =
          socket
          |> stream_insert(:passkeys, passkey)
          |> assign(:renaming, nil)

        {:noreply, socket}

      {:error, changeset} ->
        socket =
          socket
          |> assign(:rename_form, to_form(changeset, as: "rename"))
          # Force re-render the passkey line
          |> stream_insert(:passkeys, passkey)

        {:noreply, socket}
    end
  end

  def handle_event("cancel_rename", _args, socket) do
    passkey = socket.assigns.renaming

    socket =
      socket
      |> assign(renaming: nil, rename_form: nil)
      |> stream_insert(:passkeys, passkey)

    {:noreply, socket}
  end

  # --- Deletion ---

  def handle_event("delete", %{"id" => id}, socket) do
    user = socket.assigns.current_user
    passkey = Accounts.get_user_passkey!(user, id)

    case Accounts.delete_user_passkey(passkey) do
      {:ok, passkey} ->
        socket = stream_delete(socket, :passkeys, passkey)
        {:noreply, socket}

      {:error, :last_passkey} ->
        error_message = gettext("You must keep at least one passkey. Add another device first.")
        {:noreply, put_flash(socket, :error, error_message)}
    end
  end
end
