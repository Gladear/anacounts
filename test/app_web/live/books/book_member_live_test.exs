defmodule AppWeb.BookMemberLiveTest do
  use AppWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import App.AccountsFixtures
  import App.Books.MembersFixtures
  import App.BooksFixtures
  import App.TransfersFixtures

  setup [:register_and_log_in_user]

  setup %{user: user} do
    book = book_fixture()
    member = book_member_fixture(book, user_id: user.id)
    %{book: book, member: member}
  end

  test "show a member page", %{conn: conn, book: book} do
    user = user_fixture()
    member = book_member_fixture(book, user_id: user.id)

    {:ok, _live, html} = live(conn, ~p"/books/#{book}/members/#{member}")

    # display the avatar, nickname and email
    assert html =~ ~s(class="avatar)
    assert html =~ member.nickname
    assert html =~ user.email

    # display the balance
    assert html =~ "€0.00"

    # display the creation date
    assert html =~ "Joined on"
    assert html =~ ~r/\d{2}-\d{2}-\d{4}/

    # display the set revenues card, without a link since the user is already linked
    assert html =~ "Set revenues"
    refute html =~ ~p"/books/#{book}/members/#{member}/revenues"

    # display the change nickname card
    assert html =~ "Change nickname"
  end

  test "shows an unlinked member page", %{conn: conn, book: book} do
    member1 = book_member_fixture(book)
    member2 = book_member_fixture(book)

    transfer =
      money_transfer_fixture(book,
        amount: Money.new!(:EUR, 2),
        tenant_id: member1.id
      )

    _peer1 = peer_fixture(transfer, member_id: member1.id)
    _peer2 = peer_fixture(transfer, member_id: member2.id)

    {:ok, _live, html} = live(conn, ~p"/books/#{book}/members/#{member1}")

    assert html =~ member1.nickname
    assert html =~ "€1.00"

    # display the set revenues card, with a link since the member has no user
    assert html =~ "Set revenues"
    assert html =~ ~p"/books/#{book}/members/#{member1}/revenues"
  end

  test "redirects to the profile if it belongs to the current user", %{
    conn: conn,
    book: book,
    member: member
  } do
    redirected_to = ~p"/books/#{book}/profile"

    assert {:error, {:live_redirect, %{to: ^redirected_to}}} =
             live(conn, ~p"/books/#{book}/members/#{member}")
  end
end
