defmodule AppWeb.BookAccess do
  @moduledoc """
  This module provides access checking for books.
  """
  use AppWeb, :verified_routes

  import Phoenix.LiveView, only: [push_navigate: 2]

  alias App.Books
  alias App.Books.Members

  @doc """
  * :ensure_book!
  Assigns `:book` to the socket assigns based on the `"book_id"` parameter if the
  current user is a member of the book.
  Raises `Ecto.NoResultsError` if the book does not exist or the user is not a member.

  * :ensure_open_book!
  Makes sure the book is open. Redirects to the book members page if it is closed.

  * :ensure_book_member!
  Assigns `:book_member` to the socket assigns based on the `"book_member_id"` parameter.
  Raises `Ecto.NoResultsError` if the book member does not exist.

  ## Examples

    defmodule AppWeb.PageLive do
      use AppWeb, :live_view

      on_mount {AppWeb.BookAccess, :ensure_book!}
      on_mount {AppWeb.BookAccess, :ensure_book_member!}

  """
  def on_mount(:ensure_book!, params, _session, socket) do
    {:cont, mount_book!(socket, params)}
  end

  def on_mount(:ensure_open_book!, _params, _session, socket) do
    book = socket.assigns.book

    if Books.closed?(book) do
      {:halt, push_navigate(socket, to: ~p"/books/#{book}")}
    else
      {:cont, socket}
    end
  end

  def on_mount(:ensure_book_member!, params, _session, socket) do
    {:cont, mount_book_member!(socket, params)}
  end

  defp mount_book!(socket, %{"book_id" => book_id}) do
    socket
    |> Phoenix.Component.assign_new(:book, fn ->
      Books.get_book_of_user!(book_id, socket.assigns.current_user)
    end)
    |> Phoenix.Component.assign_new(:current_member, fn %{book: book, current_user: current_user} ->
      Members.get_membership(book, current_user)
    end)
  end

  defp mount_book_member!(socket, %{"book_member_id" => book_member_id}) do
    Phoenix.Component.assign_new(socket, :book_member, fn ->
      Members.get_member_of_book!(book_member_id, socket.assigns.book)
    end)
  end
end
