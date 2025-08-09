defmodule AppWeb.BookMembersLiveTest do
  use AppWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import App.AccountsFixtures
  import App.BooksFixtures
  import App.Books.MembersFixtures

  setup [:register_and_log_in_user, :book_with_member_context]

  test "displays book members", %{conn: conn, book: book} do
    _member1 = book_member_fixture(book, user_id: user_fixture().id, nickname: "Samuel")
    _member2 = book_member_fixture(book, nickname: "John")
    _other_member = book_member_fixture(book_fixture(), nickname: "Eric")

    {:ok, _live, html} = live(conn, ~p"/books/#{book}/members")

    assert html =~ "Members"
    # there are links that go to the invitation and member creation pages
    assert html =~ ~s(href="#{~p|/books/#{book}/invite|}")
    assert html =~ ~s(href="#{~p|/books/#{book}/members/new|}")
    # the members are displayed, along with their status as an icon
    assert html =~ "Samuel"
    assert html =~ ~s(class="avatar)
    assert html =~ "€0.00"

    assert html =~ "John"

    refute html =~ "Eric"
  end

  test "tiles navigate to the member page", %{conn: conn, book: book} do
    member = book_member_fixture(book)

    {:ok, live, _html} = live(conn, ~p"/books/#{book}/members")

    assert {:ok, _live, html} =
             live
             |> element("[href='/books/#{book.id}/members/#{member.id}']", member.nickname)
             |> render_click()
             |> follow_redirect(conn, ~p"/books/#{book}/members/#{member}")

    assert html =~ "Member"
    assert html =~ member.nickname
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
