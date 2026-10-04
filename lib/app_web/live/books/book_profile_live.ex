defmodule AppWeb.BookProfileLive do
  use AppWeb, :live_view

  import AppWeb.BooksComponents,
    only: [balance_card_link: 1, member_hero_avatar: 1, member_joined_at: 1]

  alias App.Balance

  on_mount {AppWeb.BookAccess, :ensure_book!}

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.app_page flash={@flash}>
      <:breadcrumb>
        <.breadcrumb_item navigate={~p"/books/#{@book}"}>
          {@book.name}
        </.breadcrumb_item>
        <.breadcrumb_item>
          {@page_title}
        </.breadcrumb_item>
      </:breadcrumb>
      <:title>{@page_title}</:title>

      <.member_hero_avatar book_member={@current_member} />

      <.card_grid>
        <.balance_card_link book_member={@current_member} />
        <.card id="expenses-share-card">
          <:title>{gettext("Share of expenses")}</:title>
          {expenses_share_string(@current_member)}
        </.card>
        <.link navigate={~p"/books/#{@book}/profile/revenues"}>
          <.card_button icon={:banknotes}>
            {gettext("Set revenues")}
          </.card_button>
        </.link>
        <.link navigate={~p"/books/#{@book}/profile/nickname"}>
          <.card_button icon={:identification}>
            {gettext("Change nickname")}
          </.card_button>
        </.link>
        <.card>
          <:title>{gettext("Joined on")}</:title>
          {member_joined_at(@current_member)}
        </.card>
        <.link navigate={~p"/users/settings"}>
          <.card_button icon={:cog_6_tooth}>
            {gettext("Go to my account")}
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
        page_title: gettext("My profile"),
        current_member: current_member
      )

    {:ok, socket}
  end

  defp expenses_share_string(book_member) do
    if Balance.has_balance_error?(book_member) do
      "XX.XX"
    else
      App.Money.to_string(book_member.expenses_share)
    end
  end
end
