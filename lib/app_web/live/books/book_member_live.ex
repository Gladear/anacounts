defmodule AppWeb.BookMemberLive do
  @moduledoc """
  The live view for the book member form.
  Displays information about a book member.
  """
  use AppWeb, :live_view

  import AppWeb.BooksComponents,
    only: [balance_card_link: 1, member_hero_avatar: 1, member_joined_at: 1]

  alias App.Accounts
  alias App.Balance
  alias App.Books.Members

  on_mount {AppWeb.BookAccess, :ensure_book!}
  on_mount {AppWeb.BookAccess, :ensure_book_member!}

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.app_page flash={@flash}>
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
        <.member_hero_avatar book_member={@book_member} />
      <% else %>
        <div class="text-center my-4">
          <.icon name={:user_circle} class="block size-[8rem] mx-auto" />
          <span class="label">{@book_member.nickname}</span>
        </div>
      <% end %>

      <.card_grid>
        <.balance_card_link book_member={@book_member} />
        <.card>
          <:title>{gettext("Joined on")}</:title>
          {member_joined_at(@book_member)}
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
        <%= if Members.archived?(@book_member) do %>
          <.link phx-click="unarchive">
            <.card_button icon={:archive_box_x_mark}>
              {gettext("Unarchive")}
            </.card_button>
          </.link>
        <% else %>
          <.link
            data-confirm={gettext("Are you sure you want to archive this member?")}
            phx-click="archive"
          >
            <.card_button icon={:archive_box}>
              {gettext("Archive")}
            </.card_button>
          </.link>
        <% end %>
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

      book_member = Balance.fill_member_balance(book_member, book)
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

  @impl Phoenix.LiveView
  def handle_event("archive", _params, socket) do
    %{book_member: book_member} = socket.assigns

    case Members.archive_book_member(book_member) do
      {:ok, book_member} ->
        {:noreply, assign(socket, :book_member, book_member)}

      {:error, reason} ->
        error_message =
          case reason do
            :linked_to_user -> gettext("The member is linked to a user and cannot be archived.")
            :has_balance -> gettext("The member's balance must be settled before archiving.")
          end

        socket = put_flash(socket, :error, error_message)
        {:noreply, socket}
    end
  end

  def handle_event("unarchive", _params, socket) do
    book_member = Members.unarchive_book_member(socket.assigns.book_member)
    {:noreply, assign(socket, :book_member, book_member)}
  end
end
