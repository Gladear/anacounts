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

    # display the balance
    assert html =~ "€0.00"

    # display the creation date
    assert html =~ "Joined on"
    assert html =~ ~r/[A-Z][a-z]+ \d{1,2}, \d{4}/

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
        amount: Decimal.new(2),
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

  describe "archive" do
    test "archives a member with a zero balance and no linked user", %{conn: conn, book: book} do
      member = book_member_fixture(book, user_id: nil)

      {:ok, live, _html} = live(conn, ~p"/books/#{book}/members/#{member}")

      html = live |> element("[phx-click='archive']") |> render_click()

      assert html =~ "Unarchive"
      refute html =~ "Archive"
    end

    test "shows an error and does not archive a member with a non-zero balance",
         %{
           conn: conn,
           book: book
         } do
      member = book_member_fixture(book, user_id: nil)
      other_member = book_member_fixture(book, user_id: nil)

      transfer = money_transfer_fixture(book, amount: Decimal.new(2), tenant_id: other_member.id)
      _peer1 = peer_fixture(transfer, member_id: member.id)
      _peer2 = peer_fixture(transfer, member_id: other_member.id)

      {:ok, live, _html} = live(conn, ~p"/books/#{book}/members/#{member}")

      html = live |> element("[phx-click='archive']") |> render_click()

      assert html =~ "The member&#39;s balance must be settled before archiving."
      assert html =~ "Archive"
      refute html =~ "Unarchive"
    end

    test "shows an error and does not archive a member linked to a user",
         %{
           conn: conn,
           book: book
         } do
      user = user_fixture()
      member = book_member_fixture(book, user_id: user.id)

      {:ok, live, _html} = live(conn, ~p"/books/#{book}/members/#{member}")

      html = live |> element("[phx-click='archive']") |> render_click()

      assert html =~ "The member is linked to a user and cannot be archived."
      assert html =~ "Archive"
      refute html =~ "Unarchive"
    end
  end

  describe "unarchive" do
    test "unarchives an archived member", %{conn: conn, book: book} do
      member =
        book_member_fixture(book, user_id: nil, archived_at: NaiveDateTime.utc_now(:second))

      {:ok, live, _html} = live(conn, ~p"/books/#{book}/members/#{member}")

      html = live |> element("[phx-click='unarchive']") |> render_click()

      assert html =~ "Archive"
      refute html =~ "Unarchive"
    end
  end
end
