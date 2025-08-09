defmodule AppWeb.BookMemberRevenuesTransfersLive do
  use AppWeb, :live_view

  import AppWeb.TransfersComponents, only: [transfer_tile: 1]
  import Ecto.Query

  alias App.Balance.BalanceConfigs
  alias App.Books.Book
  alias App.Books.BookMember
  alias App.Books.Members
  alias App.Repo
  alias App.Transfers.MoneyTransfer
  alias App.Transfers.Peer

  on_mount {AppWeb.BookAccess, :ensure_book!}

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.app_page>
      <:breadcrumb>
        {revenues_breadcrumbs(assigns)}
      </:breadcrumb>
      <:title>{@page_title}</:title>

      <.form for={%{}} phx-submit="submit">
        <section class="container space-y-2 mb-4">
          <h2 class="title-2">{gettext("Transfers")}</h2>

          <p>
            {gettext(
              "By default, only new transfers will use the new revenues." <>
                " Here, you can select existing transfers that should use the new revenues."
            )}
          </p>

          <section id="transfers" phx-update="stream" class="max-h-[33rem] overflow-auto space-y-2">
            <p id="transfers-empty" class="label hidden only:block">
              {gettext(
                "There is no transfer in the book for now. You can finish the operation safely!"
              )}
            </p>
            <label :for={{dom_id, transfer} <- @streams.transfers} id={dom_id} class="block">
              <.transfer_tile transfer={transfer}>
                <:start>
                  <.transfer_checkbox peer={transfer.current_peer} />
                </:start>
              </.transfer_tile>
            </label>
          </section>
        </section>

        <.button_group class="justify-between">
          <.button kind={:ghost} navigate={navigate_back_path(assigns)}>
            <.icon name={:chevron_left} />
            {gettext("Revenues")}
          </.button>
          <.button kind={:primary} type="submit">
            {gettext("Finish")}
          </.button>
        </.button_group>
      </.form>
    </.app_page>
    """
  end

  attr :live_action, :atom, required: true
  attr :book, Book, required: true
  attr :book_member, BookMember, required: true

  defp revenues_breadcrumbs(%{live_action: :profile} = assigns) do
    ~H"""
    <.breadcrumb_ellipsis />
    <.breadcrumb_item navigate={~p"/books/#{@book}/profile"}>
      {gettext("My profile")}
    </.breadcrumb_item>
    <.breadcrumb_item>
      {gettext("Set revenues")}
    </.breadcrumb_item>
    """
  end

  defp revenues_breadcrumbs(%{live_action: :member} = assigns) do
    ~H"""
    <.breadcrumb_ellipsis />
    <.breadcrumb_item navigate={~p"/books/#{@book}/members/#{@book_member}"}>
      {@book_member.nickname}
    </.breadcrumb_item>
    <.breadcrumb_item>
      {gettext("Set revenues")}
    </.breadcrumb_item>
    """
  end

  defp navigate_back_path(%{live_action: :profile} = assigns) do
    ~p"/books/#{assigns.book}/profile/revenues"
  end

  defp navigate_back_path(%{live_action: :member} = assigns) do
    ~p"/books/#{assigns.book}/members/#{assigns.book_member}/revenues"
  end

  attr :peer, Peer, required: true

  defp transfer_checkbox(assigns) do
    if assigns.peer.balance_config_id == nil do
      ~H"""
      <input type="hidden" name="peer_ids[]" value={@peer.id} />
      <.checkbox name="peer_ids[]" checked disabled />
      """
    else
      ~H|<.checkbox name="peer_ids[]" value={@peer.id} />|
    end
  end

  @impl Phoenix.LiveView
  def mount(params, _session, socket) do
    socket =
      socket
      |> assign(page_title: gettext("Set revenues"))
      |> mount_action(socket.assigns.live_action, params)
      |> assign_transfers()

    {:ok, socket}
  end

  defp mount_action(socket, :profile, _params) do
    assign(socket, :book_member, socket.assigns.current_member)
  end

  defp mount_action(socket, :member, %{"book_member_id" => book_member_id}) do
    book_member = Members.get_member_of_book!(book_member_id, socket.assigns.book)
    assign(socket, :book_member, book_member)
  end

  defp assign_transfers(socket) do
    %{book: book, book_member: book_member} = socket.assigns

    transfers =
      from([money_transfer: money_transfer] in MoneyTransfer.transfers_of_book_query(book),
        join: peer in Peer,
        on: peer.transfer_id == money_transfer.id,
        where: peer.member_id == ^book_member.id,
        order_by: [desc: money_transfer.date],
        select_merge: %{
          current_peer: peer
        }
      )
      |> Repo.all()

    stream(socket, :transfers, transfers)
  end

  @impl Phoenix.LiveView
  def handle_event("submit", params, socket) do
    book_member = socket.assigns.book_member

    peer_ids = Map.get(params, "peer_ids", [])
    peers = list_peers_of_member(peer_ids, book_member)

    balance_config = BalanceConfigs.get_balance_config_of_member(book_member)
    :ok = BalanceConfigs.link_balance_config_to_peers(balance_config, peers)

    redirect_path = redirect_path(book_member, socket.assigns.live_action)
    {:noreply, push_navigate(socket, to: redirect_path)}
  end

  defp list_peers_of_member(peer_ids, book_member) do
    from([peer: peer] in Peer.base_query(),
      where: peer.id in ^peer_ids,
      where: peer.member_id == ^book_member.id,
      select: map(peer, [:id])
    )
    |> Repo.all()
  end

  defp redirect_path(member, :profile), do: ~p"/books/#{member.book_id}/profile"
  defp redirect_path(member, :member), do: ~p"/books/#{member.book_id}/members/#{member}"
end
