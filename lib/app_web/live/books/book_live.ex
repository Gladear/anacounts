defmodule AppWeb.BookLive do
  use AppWeb, :live_view

  import AppWeb.BooksComponents, only: [balance_card_link: 1]
  import AppWeb.TransfersComponents, only: [transfer_tile: 1]
  import Ecto.Query

  alias App.Balance
  alias App.Balance.BalanceConfigs
  alias App.Books.BookMember
  alias App.Repo
  alias App.Transfers.MoneyTransfer

  on_mount {AppWeb.BookAccess, :ensure_book!}

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.app_page>
      <:breadcrumb>
        <.breadcrumb_item>{@page_title}</.breadcrumb_item>
      </:breadcrumb>
      <:title>{@page_title}</:title>

      <.alert_flash flash={@flash} kind={:info} class="mb-4" />

      <.link :if={@no_revenues?} navigate={~p"/books/#{@book}/profile"}>
        <.alert kind={:warning}>
          <span class="grow">{gettext("Your revenues are not set")}</span>
          <.icon name={:chevron_right} />
        </.alert>
      </.link>

      <.card_grid class="mt-4">
        <.link navigate={~p"/books/#{@book}/profile"}>
          <.card>
            <:title>My profile <.icon name={:chevron_right} /></:title>
            {@current_member.nickname}
          </.card>
        </.link>
        <.balance_card_link book_member={@current_member} />
        <.link navigate={~p"/books/#{@book}/transfers"} class="col-span-2">
          <.card>
            <:title>{gettext("Latest transfers")} <.icon name={:chevron_right} /></:title>
            <div id="transfers" phx-update="stream" class="space-y-2">
              <.tile id="transfers-empty" class="hidden only:flex bg-transparent">
                {gettext("No transfers yet")}
              </.tile>
              <.transfer_tile
                :for={{dom_id, transfer} <- @streams.latest_transfers}
                id={dom_id}
                transfer={transfer}
              />
            </div>
          </.card>
        </.link>
        <.link navigate={~p"/books/#{@book}/transfers/new"}>
          <.card_button icon={:arrows_right_left} class="h-24">
            {gettext("New payment")}
          </.card_button>
        </.link>
        <.link navigate={~p"/books/#{@book}/members"}>
          <.card class="h-24">
            <:title>{gettext("Members")} <.icon name={:chevron_right} /></:title>
            <div class="flex justify-center items-center">
              {@members_count.total} <.icon name={:user} />
            </div>
            <div class="text-sm">
              {gettext("%{count} unlinked", count: @members_count.unlinked)}
            </div>
          </.card>
        </.link>
        <.link navigate={~p"/books/#{@book}/configuration"}>
          <.card_button icon={:cog_6_tooth} class="h-24">
            {gettext("Configuration")}
          </.card_button>
        </.link>
      </.card_grid>
    </.app_page>
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    %{book: book, current_member: current_member} = socket.assigns

    current_member = Balance.fill_member_balance(current_member, book)

    socket =
      socket
      |> assign(
        page_title: book.name,
        current_member: current_member,
        no_revenues?: not BalanceConfigs.member_has_revenues?(current_member),
        members_count: members_count(book)
      )
      |> stream(:latest_transfers, latest_transfers(book))

    {:ok, socket}
  end

  defp members_count(book) do
    from([book_member: book_member] in BookMember.book_query(book),
      select: %{
        total: count(),
        unlinked: fragment("? FILTER (WHERE ?)", count(), is_nil(book_member.user_id))
      }
    )
    |> Repo.one!()
  end

  defp latest_transfers(book) do
    from([money_transfer: money_transfer] in MoneyTransfer.transfers_of_book_query(book),
      order_by: [desc: money_transfer.inserted_at],
      limit: 5
    )
    |> Repo.all()
  end
end
