defmodule AppWeb.BookTransferFormLive do
  @moduledoc """
  The money transfer form live view.
  Create or update a money transfer for the current book.
  """

  use AppWeb, :live_view

  import Ecto.Query

  alias App.Accounts.Avatars
  alias App.Books
  alias App.Books.BookMember
  alias App.Books.Members
  alias App.Repo
  alias App.Transfers
  alias App.Transfers.MoneyTransfer
  alias App.Transfers.Peer

  on_mount {AppWeb.BookAccess, :ensure_book!}

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.app_page>
      <:breadcrumb>
        <.breadcrumb_ellipsis />
        <.breadcrumb_item navigate={~p"/books/#{@book}/transfers"}>
          {gettext("Transfers")}
        </.breadcrumb_item>
        {form_breadcrumb_item(assigns)}
      </:breadcrumb>
      <:title>{@page_title}</:title>

      <.form for={@form} phx-change="validate" phx-submit="submit" class="space-y-4">
        <section id="details" class="container space-y-2">
          <h2 class="title-2">{gettext("Details")}</h2>

          <.input
            field={@form[:label]}
            type="text"
            label={gettext("Label")}
            pattern=".{1,255}"
            required
            phx-debounce
          />

          <.input field={@form[:date]} type="date" label={gettext("Date")} required phx-debounce />

          <.input
            field={@form[:balance_means]}
            type="select"
            label={gettext("How to balance?")}
            options={balance_params_options()}
          />
        </section>

        <section id="tenant" class="container space-y-2">
          <h2 class="title-2">{tenant_label(@type)}</h2>

          <div class="grid sm:grid-cols-2 gap-x-4">
            <.input
              field={@form[:tenant_id]}
              type="select"
              label={gettext("Member")}
              options={member_options(@members)}
            />
            <.input
              field={@form[:amount]}
              type="money"
              step="0.01"
              label={gettext("Amount")}
              required
              phx-debounce
            />
          </div>
        </section>

        <section id="peers" class="container space-y-2">
          <h2 class="title-2">{gettext("Members")}</h2>

          <div class="form-control-container" id="toggle-peer-weight-container" phx-update="ignore">
            <.checkbox
              id="toggle-peer-weight"
              name="display_weight"
              checked={@display_weight?}
              phx-change="toggle_display_weight"
            />
            <label for="toggle-peer-weight">{gettext("Show weight")}</label>
          </div>

          <.list>
            <.inputs_for :let={form} field={@form[:peers]}>
              <.input field={form[:member_id]} type="hidden" />

              <.list_item>
                <div class="grid grid-cols-[auto_1fr_auto] items-center gap-x-2">
                  <.peer_form_profile form={form} />

                  <.button
                    kind={:secondary}
                    type="button"
                    phx-click="remove_peer"
                    phx-value-member_id={input_value(form, :member_id)}
                    class="px-2"
                  >
                    <.icon name={:trash} />
                  </.button>
                </div>
                <div class={["mt-1", not @display_weight? && "hidden"]}>
                  <.input
                    field={form[:weight]}
                    type="number"
                    label={gettext("Weight")}
                    step="0.01"
                    min="0.01"
                    phx-debounce
                  />
                </div>
              </.list_item>
            </.inputs_for>

            <.list_item :if={members = non_peer_members(@form, @members)}>
              <div class="grid grid-cols-[auto_1fr] items-center gap-x-2">
                <.icon name={:user_plus} class="m-1" />
                <.select
                  name="peer[member_id]"
                  prompt={gettext("Add another member")}
                  options={member_options(members)}
                  phx-change="add_peer"
                />
              </div>
            </.list_item>
          </.list>

          <div class="grid sm:grid-cols-2 gap-y-2 gap-x-4">
            <.button
              kind={:secondary}
              type="button"
              disabled={has_no_peer?(@form)}
              phx-click="remove_all_peers"
            >
              <.icon name={:x_mark} />
              {gettext("Remove all")}
            </.button>
            <.button
              kind={:secondary}
              type="button"
              disabled={has_all_peers?(@form, @members)}
              phx-click="add_all_peers"
            >
              <.icon name={:users} />
              {gettext("Add everyone")}
            </.button>
          </div>
        </section>

        <.button_group>
          <.button kind={:primary} type="submit">
            {gettext("Save")}
          </.button>
        </.button_group>
      </.form>
    </.app_page>
    """
  end

  defp form_breadcrumb_item(%{live_action: :new} = assigns) do
    ~H"""
    <.breadcrumb_item>
      {form_new_title(@type)}
    </.breadcrumb_item>
    """
  end

  defp form_breadcrumb_item(%{live_action: :edit} = assigns) do
    ~H"""
    <.breadcrumb_item>
      {@page_title}
    </.breadcrumb_item>
    """
  end

  defp tenant_label(:payment), do: gettext("Paid by")
  defp tenant_label(:income), do: gettext("Received by")

  defp member_options(book_members) do
    book_members
    |> Enum.sort_by(& &1.nickname)
    |> Enum.map(&{&1.nickname, &1.id})
  end

  defp balance_params_options do
    [
      {gettext("Divide equally"), "divide_equally"},
      {gettext("Weight by revenues"), "weight_by_revenues"}
    ]
  end

  def peer_form_profile(%{form: form} = assigns) do
    member = Ecto.Changeset.fetch_field!(form.source, :member)

    assigns =
      assign(assigns, :member, member)

    ~H"""
    <.avatar src={Avatars.avatar_url(@member)} alt="" />
    <span class="label truncate">{@member.nickname}</span>
    """
  end

  defp non_peer_members(form, members) do
    peers_members_id = peers_members_id(form)

    case Enum.reject(members, &(to_string(&1.id) in peers_members_id)) do
      [] -> nil
      members -> members
    end
  end

  defp has_no_peer?(form) do
    peers = input_value(form, :peers)
    Enum.empty?(peers)
  end

  defp has_all_peers?(form, members) do
    peers_members_id = peers_members_id(form)

    Enum.all?(members, &(to_string(&1.id) in peers_members_id))
  end

  defp peers_members_id(form) do
    peers = Ecto.Changeset.get_assoc(form.source, :peers, :struct)

    Enum.map(peers, fn peer ->
      to_string(peer.member_id)
    end)
  end

  @impl Phoenix.LiveView
  def mount(params, _session, socket) do
    %{book: book, live_action: live_action} = socket.assigns
    members = Members.list_members_of_book(book)

    socket =
      socket
      |> assign(members: members)
      |> mount_action(live_action, params)

    {:ok, socket}
  end

  defp mount_action(socket, :new, params) do
    %{book: book, current_member: current_member, members: members} = socket.assigns
    type = parse_params_type(params["type"])

    if Books.closed?(book) do
      push_navigate(socket, to: ~p"/books/#{book}")
    else
      peers =
        for member <- members do
          %Peer{member_id: member.id, member: member}
        end

      form =
        %MoneyTransfer{
          date: Date.utc_today(),
          type: type,
          tenant_id: current_member.id,
          peers: peers
        }
        |> Transfers.change_money_transfer()
        |> to_money_transfer_form()

      assign(socket,
        page_title: form_new_title(type),
        form: form,
        type: type,
        display_weight?: false
      )
    end
  end

  defp mount_action(socket, :edit, %{"money_transfer_id" => money_transfer_id}) do
    money_transfer = get_money_transfer(money_transfer_id, socket)

    form =
      money_transfer
      |> Transfers.change_money_transfer()
      |> to_money_transfer_form()

    display_weight? = has_non_default_weight?(money_transfer.peers)

    assign(socket,
      page_title: money_transfer.label,
      form: form,
      type: money_transfer.type,
      display_weight?: display_weight?,
      money_transfer: money_transfer
    )
  end

  defp form_new_title(:income), do: gettext("New income")
  defp form_new_title(:payment), do: gettext("New payment")

  defp parse_params_type("income"), do: :income
  defp parse_params_type(_payment_or_nil), do: :payment

  defp get_money_transfer(money_transfer_id, socket) do
    %{book: book, members: members} = socket.assigns
    members_by_id = Map.new(members, &{&1.id, &1})

    from([money_transfer: money_transfer] in MoneyTransfer.transfers_of_book_query(book),
      where: money_transfer.id == ^money_transfer_id,
      left_join: peer in Peer,
      on: peer.transfer_id == money_transfer.id,
      left_join: member in BookMember,
      on: peer.member_id == member.id,
      order_by: [asc: member.nickname],
      preload: [peers: peer],
      select:
        struct(money_transfer, [
          :id,
          :type,
          :label,
          :date,
          :balance_means,
          :tenant_id,
          :amount,
          peers: [
            :id,
            :member_id,
            :weight
          ]
        ])
    )
    |> Repo.one!()
    |> Map.update!(:peers, fn peers ->
      for peer <- peers do
        %{peer | member: Map.fetch!(members_by_id, peer.member_id)}
      end
    end)
  end

  defp has_non_default_weight?(peers) do
    default_weight = Decimal.new(1)
    Enum.any?(peers, &(Decimal.compare(&1.weight, default_weight) != :eq))
  end

  @impl Phoenix.LiveView
  def handle_event("validate", %{"money_transfer" => money_transfer_params}, socket) do
    normalized_params = normalize_params(money_transfer_params)

    form =
      (socket.assigns[:money_transfer] || %MoneyTransfer{})
      |> Transfers.change_money_transfer(normalized_params)
      |> Map.put(:action, :validate)
      |> to_money_transfer_form(socket.assigns.members)

    {:noreply, assign(socket, :form, form)}
  end

  def handle_event("submit", %{"money_transfer" => money_transfer_params}, socket) do
    normalized_params = normalize_params(money_transfer_params)

    submit_form(socket, socket.assigns.live_action, normalized_params)
  end

  def handle_event("add_peer", %{"peer" => %{"member_id" => member_id}}, socket) do
    %{form: form, members: members} = socket.assigns

    member_id = String.to_integer(member_id)
    member = Enum.find(members, &(&1.id == member_id))

    form =
      update_form_peers(form, fn peers ->
        peer = %Peer{member_id: member_id, member: member}
        Enum.sort_by([peer | peers], & &1.member.nickname)
      end)

    {:noreply, assign(socket, :form, form)}
  end

  def handle_event("remove_peer", %{"member_id" => member_id}, socket) do
    member_id = String.to_integer(member_id)

    form =
      update_form_peers(socket.assigns.form, fn peers ->
        Enum.reject(peers, &(&1.member_id == member_id))
      end)

    {:noreply, assign(socket, :form, form)}
  end

  def handle_event("remove_all_peers", _params, socket) do
    form = put_form_peers(socket.assigns.form, [])

    {:noreply, assign(socket, :form, form)}
  end

  def handle_event("add_all_peers", _params, socket) do
    %{form: form, members: members} = socket.assigns

    form =
      update_form_peers(form, fn peers ->
        members_id =
          peers
          |> Enum.map(& &1.member_id)
          |> MapSet.new()

        new_peers =
          for member <- members, member.id not in members_id do
            %Peer{member_id: member.id, member: member}
          end

        Enum.sort_by(new_peers ++ peers, & &1.member.nickname)
      end)

    {:noreply, assign(socket, :form, form)}
  end

  def handle_event("toggle_display_weight", params, socket) do
    display_weight? = Map.has_key?(params, "display_weight")
    {:noreply, assign(socket, :display_weight?, display_weight?)}
  end

  defp submit_form(socket, :new, money_transfer_params) do
    %{book: book, current_member: current_member, type: type} = socket.assigns

    case Transfers.create_money_transfer(book, current_member, type, money_transfer_params) do
      {:ok, _money_transfer} ->
        {:noreply, push_navigate(socket, to: ~p"/books/#{book}/transfers")}

      {:error, changeset} ->
        form = to_money_transfer_form(changeset)
        {:noreply, assign(socket, :form, form)}
    end
  end

  defp submit_form(socket, :edit, money_transfer_params) do
    %{book: book, money_transfer: money_transfer} = socket.assigns

    case Transfers.update_money_transfer(money_transfer, money_transfer_params) do
      {:ok, _money_transfer} ->
        {:noreply, push_navigate(socket, to: ~p"/books/#{book}/transfers")}

      {:error, changeset} ->
        form = to_money_transfer_form(changeset)
        {:noreply, assign(socket, :form, form)}
    end
  end

  defp normalize_params(params) do
    # Amount
    params = Map.update(params, "amount", nil, &parse_money_or_nil/1)

    # Peers
    Map.put_new(params, "peers", [])
  end

  defp parse_money_or_nil(""), do: nil
  defp parse_money_or_nil(amount), do: Money.new!(:EUR, amount)

  defp to_money_transfer_form(changeset, members) do
    members_by_id = Map.new(members, &{&1.id, &1})

    changeset
    |> Ecto.Changeset.update_change(:peers, fn changesets ->
      for changeset <- changesets do
        member_id = Ecto.Changeset.fetch_field!(changeset, :member_id)
        member = Map.fetch!(members_by_id, member_id)
        Ecto.Changeset.put_assoc(changeset, :member, member)
      end
    end)
    |> to_money_transfer_form()
  end

  defp to_money_transfer_form(changeset) do
    to_form(changeset, as: "money_transfer")
  end

  defp update_form_peers(form, fun) do
    changeset = form.source

    peers = Ecto.Changeset.get_assoc(changeset, :peers, :struct)

    changeset
    |> Ecto.Changeset.put_assoc(:peers, fun.(peers))
    |> to_money_transfer_form()
  end

  defp put_form_peers(form, peers) do
    changeset = form.source

    changeset
    |> Ecto.Changeset.put_assoc(:peers, peers)
    |> to_money_transfer_form()
  end
end
