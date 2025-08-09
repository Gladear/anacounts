defmodule AppWeb.BookMemberLive do
  @moduledoc """
  The live view for the book member form.
  Displays information about a book member.
  """
  use AppWeb, :live_view

  import AppWeb.AccountsComponents, only: [hero_avatar: 1]
  import AppWeb.BooksComponents, only: [balance_card_link: 1]

  alias App.Accounts
  alias App.Balance
  alias App.Books.Members

  on_mount {AppWeb.BookAccess, :ensure_book!}
  on_mount {AppWeb.BookAccess, :ensure_book_member!}

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.app_page>
      <:breadcrumb>
        <.breadcrumb_ellipsis />
        <.breadcrumb_item navigate={~p"/books/#{@book}/members"}>
          {gettext("Members")}
        </.breadcrumb_item>
        <.breadcrumb_item>
          {@page_title}
        </.breadcrumb_item>
      </:breadcrumb>
      <:title>{@page_title}</:title>

      <%= if @user do %>
        <.hero_avatar user={@user} alt={gettext("Your avatar")} book_member={@book_member} />
      <% else %>
        <div class="text-center my-4">
          <.icon name={:user_circle} class="block size-[8rem] mx-auto" />
          <span class="label">{@book_member.nickname}</span>
        </div>
      <% end %>

      <.alert_flash flash={@flash} kind={:error} class="mb-4" />

      <.card_grid>
        <.balance_card_link book_member={@book_member} />
        <.card>
          <:title>{gettext("Joined on")}</:title>
          {format_date(@book_member.inserted_at)}
        </.card>
        <.link
          navigate={is_nil(@user) && ~p"/books/#{@book}/members/#{@book_member}/revenues"}
          aria-disabled={@user && "true"}
        >
          <.card_button icon={:banknotes}>
            {gettext("Set revenues")}
          </.card_button>
        </.link>
        <.link navigate={~p"/books/#{@book}/members/#{@book_member}/nickname"}>
          <.card_button icon={:identification}>
            {gettext("Change nickname")}
          </.card_button>
        </.link>
      </.card_grid>
    </.app_page>
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    %{book: book, book_member: book_member, current_member: current_member} = socket.assigns

    if book_member.id == current_member.id do
      {:ok, push_navigate(socket, to: ~p"/books/#{book.id}/profile")}
    else
      %{book: book, book_member: book_member} = socket.assigns

      # FIXME expensive, cache members balance
      book_member =
        book
        |> Members.list_members_of_book()
        |> Balance.fill_members_balance()
        |> Enum.find(&(&1.id == book_member.id))

      user = book_member.user_id && Accounts.get_user!(book_member.user_id)

      socket =
        assign(socket,
          page_title: gettext("Member"),
          book_member: book_member,
          user: user
        )

      {:ok, socket}
    end
  end
end
