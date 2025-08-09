defmodule AppWeb.BookConfigurationLiveTest do
  use AppWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import App.BooksFixtures
  import App.Books.MembersFixtures

  alias App.Books
  alias App.Repo

  setup :register_and_log_in_user

  setup %{user: user} do
    book = book_fixture()
    member = book_member_fixture(book, user_id: user.id)
    %{book: book, member: member}
  end

  describe "change name card" do
    test "links to name configuration", %{conn: conn, book: book} do
      {:ok, _live, html} = live(conn, ~p"/books/#{book}/configuration")

      href_attribute =
        html
        |> Floki.parse_document!()
        |> Floki.attribute(".card-grid a:nth-child(1)", "href")

      assert href_attribute == [~p"/books/#{book}/configuration/name"]
    end
  end

  describe "close/reopen card" do
    test "closes book", %{conn: conn, book: book} do
      {:ok, live, _html} = live(conn, ~p"/books/#{book}/configuration")

      assert html =
               live
               |> element(~s([phx-click="close"]), "Close book")
               |> render_click()

      assert html =~ "Reopen book"
      assert book |> Repo.reload() |> Books.closed?()
    end

    test "reopens book", %{conn: conn, book: book} do
      book = Books.close_book!(book)

      {:ok, live, _html} = live(conn, ~p"/books/#{book}/configuration")

      assert html =
               live
               |> element(~s([phx-click="reopen"]), "Reopen book")
               |> render_click()

      assert html =~ "Close book"
      refute book |> Repo.reload() |> Books.closed?()
    end
  end

  describe "delete card" do
    test "confirms deletion", %{conn: conn, book: book} do
      {:ok, _live, html} = live(conn, ~p"/books/#{book}/configuration")

      confirm_attribute =
        html
        |> Floki.parse_document!()
        |> Floki.attribute(".card-grid a:nth-child(3)", "data-confirm")

      assert confirm_attribute ==
               ["Are you sure you want to delete this book? This operation is irreversible."]
    end

    test "deletes book", %{conn: conn, book: book} do
      {:ok, live, _html} = live(conn, ~p"/books/#{book}/configuration")

      assert {:ok, _live, html} =
               live
               |> element(~s([phx-click="delete"]), "Delete book")
               |> render_click()
               |> follow_redirect(conn, ~p"/books")

      refute html =~ book.name
    end
  end
end
