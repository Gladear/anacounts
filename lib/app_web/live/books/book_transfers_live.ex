defmodule AppWeb.BookTransfersLive do
  @moduledoc """
  The money transfer index live view.
  Shows money transfers for the current book.
  """

  use AppWeb, :live_view

  import Ecto.Query
  import AppWeb.FiltersComponents
  import AppWeb.TransfersComponents, only: [transfer_details: 1]

  alias App.Books.BookMember
  alias App.Repo
  alias App.Transfers
  alias App.Transfers.Peer

  on_mount {AppWeb.BookAccess, :ensure_book!}

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.app_page>
      <:breadcrumb>
        <.breadcrumb_item navigate={~p"/books/#{@book}"}>
          {@book.name}
        </.breadcrumb_item>
        <.breadcrumb_item>
          {@page_title}
        </.breadcrumb_item>
      </:breadcrumb>
      <:title>{@page_title}</:title>

      <.card_grid class="mb-4">
        <.link navigate={~p"/books/#{@book}/transfers/new?type=income"}>
          <.card_button icon={:arrow_down_on_square}>
            {gettext("New income")}
          </.card_button>
        </.link>
        <.link navigate={~p"/books/#{@book}/transfers/new"}>
          <.card_button icon={:arrow_up_on_square} color={:primary}>
            {gettext("New payment")}
          </.card_button>
        </.link>
      </.card_grid>

      <.filters
        id="transfers-filters"
        phx-change="filters"
        filters={[
          multi_select(
            name: "tenanted_by",
            label: gettext("Tenanted by"),
            options: [
              me: gettext("Me"),
              others: gettext("Others")
            ]
          ),
          multi_select(
            name: "created_by",
            label: gettext("Created by"),
            options: @book_members_options
          ),
          sort_by(
            options: [
              most_recent: gettext("Most recent"),
              oldest: gettext("Oldest"),
              last_created: gettext("Last created"),
              first_created: gettext("First created")
            ],
            default: :most_recent
          )
        ]}
      />

      <div
        id="transfers"
        phx-update="stream"
        phx-viewport-top={@page > 1 && "prev-page"}
        phx-viewport-bottom={!@end_of_timeline? && "next-page"}
        class={[
          "space-y-4",
          if(@end_of_timeline?, do: "pb-10", else: "pb-[200vh]"),
          if(@page > 1, do: "pt-[200vh]")
        ]}
      >
        <.transfer_details
          :for={{dom_id, transfer} <- @streams.transfers}
          id={dom_id}
          transfer={transfer}
        >
          <:extra>
            <.divider />
            <div class="grid grid-cols-2 gap-2">
              <.button
                :if={transfer.type != :reimbursement}
                kind={:secondary}
                navigate={~p"/books/#{@book}/transfers/#{transfer}/edit"}
              >
                <.icon name={:pencil} />
                {gettext("Edit")}
              </.button>
              <.button
                kind={:secondary}
                phx-click="delete"
                phx-value-id={transfer.id}
                data-confirm={gettext("Are you sure you want to delete the transfer?")}
              >
                <.icon name={:trash} />
                {gettext("Delete")}
              </.button>
            </div>
          </:extra>
        </.transfer_details>
      </div>
    </.app_page>
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(
        page_title: gettext("Transfers"),
        # pagination
        page: 1,
        per_page: 25
      )
      |> assign_book_members_options()
      |> assign_filters(%{"sort_by" => "most_recent"})
      |> paginate_transfers(1)

    {:ok, socket}
  end

  defp paginate_transfers(socket, new_page) when new_page >= 1 do
    %{book: book, filters: filters, per_page: per_page, page: cur_page} = socket.assigns

    transfers = list_transfers(book, filters, new_page, per_page)
    superior_page? = new_page >= cur_page

    {transfers, at, limit} =
      if superior_page? do
        {transfers, -1, per_page * 3 * -1}
      else
        {Enum.reverse(transfers), 0, per_page * 3}
      end

    if Enum.empty?(transfers) do
      socket
      |> assign(end_of_timeline?: superior_page?)
      # ensure the stream is at least initialized
      |> stream(:transfers, [])
    else
      socket
      |> assign(end_of_timeline?: false, page: new_page)
      |> stream(:transfers, transfers, at: at, limit: limit)
    end
  end

  defp list_transfers(book, filters, page, per_page) do
    book
    |> Transfers.list_transfers_of_book(
      filters: filters,
      offset: (page - 1) * per_page,
      limit: per_page
    )
    # TODO optimize preload, the peers are only necessary for reimbursement transfers
    |> Repo.preload(
      tenant: BookMember.base_query(),
      peers:
        Peer.base_query()
        |> select([:id, :member_id])
        |> preload(member: ^(BookMember.base_query() |> select([:nickname])))
    )
  end

  @impl Phoenix.LiveView
  def handle_event("filters", filters, socket) do
    socket =
      socket
      |> assign_filters(filters)
      |> stream(:transfers, [], reset: true)
      |> paginate_transfers(1)

    {:noreply, socket}
  end

  def handle_event("next-page", _params, socket) do
    {:noreply, paginate_transfers(socket, socket.assigns.page + 1)}
  end

  def handle_event("prev-page", %{"_overran" => true}, socket) do
    {:noreply, paginate_transfers(socket, 1)}
  end

  def handle_event("prev-page", _params, socket) do
    if socket.assigns.page > 1 do
      {:noreply, paginate_transfers(socket, socket.assigns.page - 1)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("delete", %{"id" => money_transfer_id}, socket) do
    book = socket.assigns.book

    money_transfer = Transfers.get_money_transfer_of_book!(money_transfer_id, book)

    {:ok, _} = Transfers.delete_money_transfer(money_transfer)

    socket = stream_delete(socket, :transfers, money_transfer)

    {:noreply, socket}
  end

  defp assign_book_members_options(socket) do
    book = socket.assigns.book

    book_members_options =
      from(book_member in BookMember.book_query(book),
        order_by: [asc: book_member.nickname],
        select: {book_member.id, book_member.nickname}
      )
      |> Repo.all()

    assign(socket, :book_members_options, book_members_options)
  end

  defp assign_filters(socket, filters) do
    current_member = socket.assigns.current_member

    filters =
      Map.update(filters, "tenanted_by", nil, fn
        ["me"] -> current_member.id
        ["others"] -> {:not, current_member.id}
        _nil_or_multiple -> nil
      end)

    assign(socket, :filters, filters)
  end
end
