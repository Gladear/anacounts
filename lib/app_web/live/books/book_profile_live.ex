defmodule AppWeb.BookProfileLive do
  use AppWeb, :live_view

  import AppWeb.AccountsComponents, only: [hero_avatar: 1]
  import AppWeb.BooksComponents, only: [balance_card_link: 1]

  alias App.Balance
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

      <.hero_avatar user={@current_user} alt={gettext("Your avatar")} book_member={@current_member} />

      <.card_grid>
        <.balance_card_link book_member={@current_member} />
        <.card>
          <:title>{gettext("Joined on")}</:title>
          {format_date(@current_member.inserted_at)}
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

    # FIXME expensive, cache members balance
    current_member =
      book
      |> Members.list_members_of_book()
      |> Balance.fill_members_balance()
      |> Enum.find(&(&1.id == current_member.id))

    socket =
      socket
      |> assign(
        page_title: gettext("My profile"),
        current_member: current_member
      )

    {:ok, socket}
  end
end
