defmodule AppWeb.BookMembersLive do
  @moduledoc """
  The book member index live view.
  Displays the members of a book.
  """

  use AppWeb, :live_view

  import AppWeb.BooksComponents, only: [balance_text: 1]

  alias App.Accounts.Avatars
  alias App.Balance
  alias App.Books
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
        <.link navigate={~p"/books/#{@book}/invite"} aria-disabled={Books.closed?(@book) && "true"}>
          <.card_button color={:primary} icon={:envelope}>
            {gettext("Invite people")}
          </.card_button>
        </.link>
        <.link
          navigate={~p"/books/#{@book}/members/new"}
          aria-disabled={Books.closed?(@book) && "true"}
        >
          <.card_button icon={:user_plus}>
            {gettext("Create manually")}
          </.card_button>
        </.link>
      </.card_grid>

      <div id="members" phx-update="stream" class="space-y-4">
        <.link
          :for={{dom_id, member} <- @streams.members}
          id={dom_id}
          navigate={~p"/books/#{@book}/members/#{member}"}
          class="block"
        >
          <.tile>
            <div class="grow grid grid-cols-[1fr_9rem] grid-flow-col">
              <div class="row-span-2 flex items-center gap-2 truncate">
                <.member_avatar member={member} />
                <span class="label">{member.nickname}</span>
              </div>
              <div class="text-right pr-5">
                <.balance_text book_member={member} />
              </div>
              <.button kind={:ghost} class="h-xs px-1">
                {gettext("View profile")}
                <.icon name={:chevron_right} />
              </.button>
            </div>
          </.tile>
        </.link>
      </div>
    </.app_page>
    """
  end

  defp member_avatar(assigns) do
    if has_user?(assigns.member) do
      ~H|<.avatar src={Avatars.avatar_url(@member)} alt="" />|
    else
      ~H|<.icon name={:user_circle} class="m-1" />|
    end
  end

  defp has_user?(book_member) do
    book_member.user_id != nil
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    book = socket.assigns.book

    members =
      book
      |> Members.list_members_of_book()
      |> Balance.fill_members_balance()

    socket =
      socket
      |> assign(:page_title, gettext("Members"))
      |> stream(:members, members)

    {:ok, socket}
  end
end
