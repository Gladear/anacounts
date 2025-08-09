defmodule AppWeb.BookAccessTest do
  use AppWeb.ConnCase, async: true

  import App.BooksFixtures
  import App.Books.MembersFixtures

  alias AppWeb.BookAccess
  alias Phoenix.LiveView

  setup :register_and_log_in_user

  setup %{user: user} do
    socket =
      %LiveView.Socket{}
      |> Phoenix.Component.assign(:current_user, user)

    %{socket: socket}
  end

  describe "on_mount: ensure_book!" do
    test "assigns the book found in parameters", %{socket: socket, user: user} do
      book = book_fixture()
      member = book_member_fixture(book, user_id: user.id, role: :creator)

      {:cont, updated_socket} =
        BookAccess.on_mount(:ensure_book!, %{"book_id" => book.id}, nil, socket)

      assert updated_socket.assigns.book.id == book.id
      assert updated_socket.assigns.current_member.id == member.id
    end

    test "raises if the user does not have access to the book", %{socket: socket} do
      book = book_fixture()

      assert_raise Ecto.NoResultsError, fn ->
        BookAccess.on_mount(:ensure_book!, %{"book_id" => book.id}, nil, socket)
      end
    end

    test "raises if the book is not found", %{socket: socket} do
      assert_raise Ecto.NoResultsError, fn ->
        BookAccess.on_mount(:ensure_book!, %{"book_id" => 0}, nil, socket)
      end
    end
  end

  describe "on_mount: ensure_book_member!" do
    setup %{socket: socket} do
      book = book_fixture()

      socket =
        socket
        |> Phoenix.Component.assign(:book, book)

      %{socket: socket, book: book}
    end

    test "assigns the book member found in parameters", %{socket: socket, book: book} do
      book_member = book_member_fixture(book)

      {:cont, updated_socket} =
        BookAccess.on_mount(
          :ensure_book_member!,
          %{"book_member_id" => book_member.id},
          nil,
          socket
        )

      assert updated_socket.assigns.book_member.id == book_member.id
    end

    test "raises if the member is not part of the book", %{socket: socket} do
      book_member = book_member_fixture(book_fixture())

      assert_raise Ecto.NoResultsError, fn ->
        BookAccess.on_mount(
          :ensure_book_member!,
          %{"book_member_id" => book_member.id},
          nil,
          socket
        )
      end
    end

    test "raises if the member does not exist", %{socket: socket} do
      assert_raise Ecto.NoResultsError, fn ->
        BookAccess.on_mount(:ensure_book_member!, %{"book_member_id" => 0}, nil, socket)
      end
    end
  end
end
