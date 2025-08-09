defmodule AppWeb.BookCreationLiveTest do
  use AppWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias App.Books.Book
  alias App.Books.BookMember
  alias App.Repo

  setup :register_and_log_in_user

  test "renders the book creation form", %{conn: conn} do
    {:ok, _live, html} = live(conn, ~p"/books/new")

    assert html =~ "New book"
    assert html =~ "Name"
    assert html =~ "Nickname"
  end

  test "creates a book", %{conn: conn, user: user} do
    {:ok, live, _html} = live(conn, ~p"/books/new")

    {:ok, _live, html} =
      live
      |> form("form",
        book: %{
          name: "Book name",
          nickname: "Creator name"
        }
      )
      |> render_submit()
      |> follow_redirect(conn)

    assert html =~ "Book name"

    assert book = Repo.get_by(Book, name: "Book name")
    assert book.closed_at == nil
    assert book.deleted_at == nil

    member = Repo.get_by(BookMember, book_id: book.id, user_id: user.id)
    assert member.nickname == "Creator name"
    assert member.role == :creator
  end

  test "shows errors from both name and nickname inputs", %{conn: conn} do
    {:ok, live, _html} = live(conn, ~p"/books/new")

    assert live
           |> form("form",
             book: %{
               name: "",
               nickname: "Valid nickname"
             }
           )
           |> render_submit()
           |> Kernel.=~("can&#39;t be blank")

    assert live
           |> form("form",
             book: %{
               name: "Valid name",
               nickname: ""
             }
           )
           |> render_submit()
           |> Kernel.=~("can&#39;t be blank")
  end
end
