defmodule AppWeb.BookConfigurationNameLiveTest do
  use AppWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import App.BooksFixtures
  import App.Books.MembersFixtures

  alias App.Repo

  setup :register_and_log_in_user

  setup %{user: user} do
    book = book_fixture()
    member = book_member_fixture(book, user_id: user.id)
    %{book: book, member: member}
  end

  test "shows the form", %{conn: conn, book: book} do
    {:ok, _live, html} = live(conn, ~p"/books/#{book}/configuration/name")

    assert html =~ "Change name"
    assert html =~ book.name
    assert html =~ "<input"
  end

  test "updates the book name", %{conn: conn, book: book} do
    {:ok, live, _html} = live(conn, ~p"/books/#{book}/configuration/name")

    assert {:ok, _, html} =
             live
             |> form("form", book: %{name: "New updated name"})
             |> render_submit()
             |> follow_redirect(conn, ~p"/books/#{book}/configuration")

    assert html =~ "New updated name"

    book = Repo.reload(book)
    assert book.name == "New updated name"
  end

  test "shows an error message when the name is invalid", %{conn: conn, book: book} do
    {:ok, live, _html} = live(conn, ~p"/books/#{book}/configuration/name")

    html =
      live
      |> form("form", book: %{name: ""})
      |> render_submit()

    assert html =~ "can&#39;t be blank"
  end
end
