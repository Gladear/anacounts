defmodule AppWeb.BooksLiveTest do
  use AppWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import App.BooksFixtures
  import App.Books.MembersFixtures

  setup :register_and_log_in_user

  test "lists all accounts_books", %{conn: conn, user: user} do
    book = book_fixture()
    _member = book_member_fixture(book, user_id: user.id)

    {:ok, _index_live, html} = live(conn, ~p"/books")

    assert html =~ book.name
  end

  test "links to books transfers", %{conn: conn, user: user} do
    book = book_fixture()
    _member = book_member_fixture(book, user_id: user.id)

    {:ok, index_live, _html} = live(conn, ~p"/books")

    assert {:ok, _, html} =
             index_live
             |> element("[href='/books/#{book.id}']", book.name)
             |> render_click()
             |> follow_redirect(conn, ~p"/books/#{book.id}")

    assert html =~ book.name
  end
end
