defmodule AppWeb.BookMemberCreationLiveTest do
  use AppWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import App.BooksFixtures
  import App.Books.MembersFixtures

  alias App.Repo

  alias App.Books.BookMember

  setup [:register_and_log_in_user, :book_with_member_context]

  describe "/books/:book_id/members/new" do
    test "show the member new page", %{conn: conn, book: book} do
      {:ok, live, _html} = live(conn, ~p"/books/#{book}/members/new")

      assert {:ok, _live, _html} =
               live
               |> form("form", book_member: %{nickname: "Nickname"})
               |> render_submit()
               |> follow_redirect(conn)

      assert member = Repo.get_by!(BookMember, book_id: book.id, nickname: "Nickname")
      assert member.book_id == book.id
    end
  end

  # Depends on :register_and_log_in_user
  defp book_with_member_context(%{user: user} = context) do
    book = book_fixture()
    member = book_member_fixture(book, user_id: user.id, role: :creator)

    Map.merge(context, %{
      book: book,
      member: member
    })
  end
end
