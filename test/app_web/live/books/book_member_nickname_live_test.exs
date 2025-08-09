defmodule AppWeb.BookMemberNicknameLiveTest do
  use AppWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import App.Books.MembersFixtures
  import App.BooksFixtures

  alias App.Repo

  setup :register_and_log_in_user

  setup %{user: user} do
    book = book_fixture()
    member = book_member_fixture(book, user_id: user.id, nickname: "MemberNickname")

    %{book: book, member: member}
  end

  describe "/books/:book_id/profile/nickname" do
    test "shows the nickname change page", %{conn: conn, book: book, member: member} do
      {:ok, _live, html} = live(conn, ~p"/books/#{book}/profile/nickname")

      assert html =~ "Change nickname"
      assert html =~ "This is your current nickname"
      assert html =~ member.nickname
    end

    test "updates the member nickname", %{conn: conn, book: book, member: member} do
      {:ok, live, _html} = live(conn, ~p"/books/#{book}/profile/nickname")

      {:ok, _live, _html} =
        live
        |> form("form", book_member: %{nickname: "Updated Nickname"})
        |> render_submit()
        |> follow_redirect(conn, ~p"/books/#{book}/profile")

      member = Repo.reload(member)
      assert member.nickname == "Updated Nickname"
    end

    test "validates the form fields", %{conn: conn, book: book} do
      {:ok, live, _html} = live(conn, ~p"/books/#{book}/profile/nickname")

      assert live
             |> form("form", book_member: %{nickname: ""})
             |> render_submit() =~ "can&#39;t be blank"
    end
  end

  describe "/books/:book_id/members/:member_id/nickname" do
    setup %{book: book} do
      member = book_member_fixture(book, nickname: "OtherMemberNickname")
      %{member: member}
    end

    test "shows the nickname change page", %{conn: conn, book: book, member: member} do
      {:ok, _live, html} = live(conn, ~p"/books/#{book}/members/#{member}/nickname")

      assert html =~ "Change nickname"
      assert html =~ "This is the current nickname of the member"
      assert html =~ member.nickname
    end

    test "updates the member nickname", %{conn: conn, book: book, member: member} do
      {:ok, live, _html} = live(conn, ~p"/books/#{book}/members/#{member}/nickname")

      {:ok, _live, _html} =
        live
        |> form("form", book_member: %{nickname: "Updated Nickname"})
        |> render_submit()
        |> follow_redirect(conn, ~p"/books/#{book}/members/#{member}")

      member = Repo.reload(member)
      assert member.nickname == "Updated Nickname"
    end

    test "responds with not found if the book or member does not exist", %{
      conn: conn,
      book: book,
      member: member
    } do
      assert_raise Ecto.NoResultsError, fn ->
        live(conn, ~p"/books/0/members/#{member}/nickname")
      end

      assert_raise Ecto.NoResultsError, fn ->
        live(conn, ~p"/books/#{book}/members/0/nickname")
      end
    end

    test "responds with not found if the book member does not belongs to the book", %{
      conn: conn,
      book: book
    } do
      other_member = book_member_fixture(book_fixture())

      assert_raise Ecto.NoResultsError, fn ->
        live(conn, ~p"/books/#{book}/members/#{other_member}/nickname")
      end
    end
  end
end
