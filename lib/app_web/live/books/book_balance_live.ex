defmodule AppWeb.BookBalanceLive do
  use AppWeb, :live_view

  import AppWeb.BooksComponents, only: [balance_card: 1]

  alias App.Balance
  alias App.Balance.BalanceError
  alias App.Books.Book
  alias App.Books.BookMember
  alias App.Books.Members

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
        <.balance_card book_member={@current_member} />
        <.link navigate={~p"/books/#{@book}/reimbursements/new"}>
          <.card_button icon={:credit_card}>
            {gettext("Manual reimbursement")}
          </.card_button>
        </.link>
      </.card_grid>

      <%= if @balance_errors != nil do %>
        <section class="space-y-4" id="transaction-errors">
          <.alert kind={:error}>
            {gettext("Some information is missing to balance the book")}
          </.alert>
          <.balance_error_tile
            :for={balance_error <- @balance_errors}
            book={@book}
            balance_error={balance_error}
          />
        </section>
      <% else %>
        <section class="space-y-4" phx-update="stream" id="transactions">
          <.link
            :for={{dom_id, transaction} <- @streams.transactions}
            id={dom_id}
            navigate={
              ~p"/books/#{@book}/reimbursements/new?from=#{transaction.from.id}&to=#{transaction.to.id}&amount=#{Money.to_string!(transaction.amount)}"
            }
            class="block"
          >
            <.tile>
              <div class="grid grid-rows-2 grid-cols-[1fr_9rem] items-center grid-flow-col grow">
                <div class="truncate">
                  <.member_nickname book_member={transaction.from} current_member={@current_member} />
                  owes
                  <.member_nickname book_member={transaction.to} current_member={@current_member} />
                </div>
                <span class="label">{transaction.amount}</span>
                <.button kind={:ghost} class="row-span-2">
                  {gettext("Settle up")} <.icon name={:chevron_right} />
                </.button>
              </div>
            </.tile>
          </.link>
        </section>
      <% end %>
    </.app_page>
    """
  end

  attr :book, Book, required: true
  attr :balance_error, BalanceError, required: true

  defp balance_error_tile(assigns) do
    case assigns.balance_error.kind do
      :revenues_missing ->
        ~H"""
        <.link navigate={~p"/books/#{@book}/members/#{@balance_error.extra.member_id}"} class="block">
          <.tile class="justify-between">
            <div class="truncate">
              <span class="label">{@balance_error.private.member_nickname}</span>
              <span class="font-normal">did not set their revenues.</span>
            </div>
            <.button kind={:ghost}>
              {gettext("Fix it")} <.icon name={:chevron_right} />
            </.button>
          </.tile>
        </.link>
        """
    end
  end

  # Highlight the nickname of the current member
  #
  attr :book_member, BookMember, required: true
  attr :current_member, BookMember, required: true

  defp member_nickname(%{book_member: %{id: id}, current_member: %{id: id}} = assigns) do
    ~H"""
    <span class="label text-theme-500">{@book_member.nickname}</span>
    """
  end

  defp member_nickname(assigns) do
    ~H"""
    <span class="label">{@book_member.nickname}</span>
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    %{book: book, current_member: current_member} = socket.assigns

    members =
      book
      |> Members.list_members_of_book()
      |> Balance.fill_members_balance()

    current_member = Enum.find(members, &(&1.id == current_member.id))

    socket =
      socket
      |> assign(
        page_title: gettext("Balance"),
        current_member: current_member
      )
      |> assign_transactions(members)

    {:ok, socket, temporary_assigns: [balance_errors: []]}
  end

  defp assign_transactions(socket, members) do
    case Balance.transactions(members) do
      {:ok, transactions} ->
        socket
        |> assign(balance_errors: nil)
        |> stream(:transactions, transactions)

      {:error, balance_errors} ->
        assign(socket, balance_errors: balance_errors)
    end
  end
end
