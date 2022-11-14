defmodule AppWeb.BookMemberLiveTest do
  use AppWeb.ConnCase

  import Phoenix.LiveViewTest
  import App.AuthFixtures
  import App.BooksFixtures
  import App.Books.MembersFixtures

  describe "Index" do
    setup [:register_and_log_in_user, :book_with_member_context]

    test "displays book members", %{conn: conn, book: book} do
      _member = book_member_fixture(book, user_fixture(display_name: "Samuel"))

      {:ok, _show_live, html} = live(conn, Routes.book_member_index_path(conn, :index, book))

      # the book name is the main title
      assert html =~ book.name <> "\n</h1>"
      # the tabs are displayed
      assert html =~ "Members"
      # there is a link to go to the invitations page
      assert html =~ ~s{href="#{Routes.invitation_index_path(conn, :index, book)}"}
      # the member is displayed, along with its balance and join status
      # FIXME It's not possible to set the `display_name` in the fixture
      # assert html =~ "Samuel"
      assert html =~ Money.new(0, :EUR) |> Money.to_string()
      assert html =~ "Joined"
    end

    test "deletes book", %{conn: conn, book: book} do
      {:ok, show_live, _html} = live(conn, Routes.book_member_index_path(conn, :index, book))

      assert {:ok, _, html} =
               show_live
               |> element("#delete-book", "Delete")
               |> render_click()
               |> follow_redirect(conn, Routes.book_index_path(conn, :index))

      assert html =~ "Book deleted successfully"
      refute html =~ book.name
    end
  end

  # Depends on :register_and_log_in_user
  defp book_with_member_context(%{user: user} = context) do
    book = book_fixture()
    member = book_member_fixture(book, user, role: :creator)

    Map.merge(context, %{
      book: book,
      member: member
    })
  end
end
