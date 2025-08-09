defmodule AppWeb.BookInvitationController do
  @moduledoc """
  Let users join books by opening invitations.

  This controller is responsible for handling any requests that match
  `/invitations/:token`, where `:token` is the token of the invitation. When an invitation
  is open, the user is asked the member they want to join as. If the member is new, a new
  member is created and linked to the user. If the member already exists, the user is
  linked to the existing member.
  """

  use AppWeb, :controller

  alias App.Books
  alias App.Books.Members

  plug :get_book_by_token
  plug :ensure_user_is_not_member_of_book
  plug :get_member when action in [:edit, :update]

  plug :put_layout, html: {AppWeb.Layouts, :auth}
  plug :set_page_title

  def show(conn, _opts) do
    members = Members.list_unlinked_members_of_book(conn.assigns.book)

    render(conn, members: members)
  end

  def new(conn, _params) do
    render(conn, form: to_form(%{"nickname" => ""}, as: :book_member))
  end

  def create(conn, %{"book_member" => book_member_params}) do
    %{book: book, current_user: current_user} = conn.assigns

    case Members.create_book_member_for_user(book, current_user, book_member_params) do
      {:ok, _book_member} ->
        conn
        |> put_flash(:info, gettext("You have been added to the book"))
        |> redirect(to: ~p"/books/#{book}")

      {:error, changeset} ->
        render(conn, :new, form: to_form(changeset))
    end
  end

  def edit(conn, _params) do
    render(conn)
  end

  def update(conn, _params) do
    %{book: book, member: member, current_user: current_user} = conn.assigns

    Members.link_book_member_to_user(member, current_user)

    conn
    |> put_flash(:info, gettext("You have been added to the book"))
    |> redirect(to: ~p"/books/#{book}")
  end

  defp get_book_by_token(conn, _opts) do
    %{"token" => token} = conn.params

    if book = Books.get_book_by_invitation_token(token) do
      merge_assigns(conn, token: token, book: book)
    else
      conn
      |> put_flash(:error, gettext("Invitation link is invalid or it has expired"))
      |> redirect(to: ~p"/books")
      |> halt()
    end
  end

  defp ensure_user_is_not_member_of_book(conn, _opts) do
    %{book: book, current_user: current_user} = conn.assigns

    if Members.get_membership(book, current_user) do
      conn
      |> put_flash(:info, gettext("You are already part of this book."))
      |> redirect(to: ~p"/books/#{book}")
      |> halt()
    else
      conn
    end
  end

  defp get_member(conn, _opts) do
    book_member_id = conn.params["book_member_id"]
    book = conn.assigns.book

    member = Members.get_member_of_book!(book_member_id, book)

    assign(conn, :member, member)
  end

  defp set_page_title(conn, _opts) do
    assign(conn, :page_title, gettext("Join book"))
  end
end
