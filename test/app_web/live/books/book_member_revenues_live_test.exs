defmodule AppWeb.BookMemberRevenuesLiveTest do
  use AppWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import App.AccountsFixtures
  import App.Balance.BalanceConfigsFixtures
  import App.Books.MembersFixtures
  import App.BooksFixtures

  alias App.Balance.BalanceConfig
  alias App.Books.BookMember
  alias App.Repo

  setup :register_and_log_in_user

  setup %{user: user} do
    book = book_fixture()
    member = book_member_fixture(book, user_id: user.id, nickname: "MemberNickname")

    %{book: book, member: member}
  end

  describe "/books/:book_id/profile/revenues" do
    test "shows the revenues form", %{conn: conn, book: book} do
      {:ok, _live, html} = live(conn, ~p"/books/#{book}/profile/revenues")

      assert html =~ "Set revenues"
      assert html =~ "<input"
      assert html =~ "Continue"
    end

    test "creates a new balance config", %{conn: conn, book: book, member: member, user: user} do
      {:ok, live, _html} = live(conn, ~p"/books/#{book}/profile/revenues")

      assert {:ok, _live, html} =
               live
               |> form("form", balance_config: %{revenues: 1000})
               |> render_submit()
               |> follow_redirect(conn, ~p"/books/#{book}/profile/revenues/transfers")

      assert html =~ "Set revenues"

      member = Repo.reload!(member)
      assert balance_config = Repo.get(BalanceConfig, member.balance_config_id)
      assert balance_config.owner_id == user.id
      assert balance_config.revenues == 1000
    end

    test "validates the revenues", %{conn: conn, book: book} do
      {:ok, live, _html} = live(conn, ~p"/books/#{book}/profile/revenues")

      assert html =
               live
               |> form("form", balance_config: %{revenues: -1})
               |> render_submit()

      assert html =~ "must be greater than or equal to 0"
    end

    test "displays a message when there is no current balance config", %{conn: conn, book: book} do
      {:ok, _live, html} = live(conn, ~p"/books/#{book}/profile/revenues")

      assert html =~ "You have not set your revenues yet."
    end

    test "displays a message when the user is the owner of the balance config", %{
      conn: conn,
      book: book,
      member: member,
      user: user
    } do
      balance_config = balance_config_fixture(owner_id: user.id, revenues: 7654)
      _member = member |> BookMember.change_balance_config(balance_config) |> Repo.update!()

      {:ok, _live, html} = live(conn, ~p"/books/#{book}/profile/revenues")

      assert html =~ "This is your current revenues"
      assert html =~ "7654"
    end

    test "displays a message when the user is not the owner of the balance config", %{
      conn: conn,
      book: book,
      member: member
    } do
      balance_config = balance_config_fixture()
      _member = member |> BookMember.change_balance_config(balance_config) |> Repo.update!()

      {:ok, _live, html} = live(conn, ~p"/books/#{book}/profile/revenues")

      assert html =~ "You cannot see your current revenues because they were set by someone else."
    end
  end

  describe "/books/:book_id/members/:member_id/revenues" do
    test "shows the revenues form", %{conn: conn, book: book} do
      member = book_member_fixture(book)

      {:ok, _live, html} = live(conn, ~p"/books/#{book}/members/#{member}/revenues")

      assert html =~ "Set revenues"
      assert html =~ "<input"
      assert html =~ "Continue"
    end

    test "redirects when the member is linked to a user", %{conn: conn, book: book} do
      user = user_fixture()
      member = book_member_fixture(book, user_id: user.id)

      expected_path = ~p"/books/#{book}/members/#{member}"

      assert {:error, {:live_redirect, %{to: ^expected_path}}} =
               live(conn, ~p"/books/#{book}/members/#{member}/revenues")
    end

    test "creates a new balance config, without deleting the former one", %{
      conn: conn,
      book: book,
      user: user
    } do
      former_balance_config = balance_config_fixture(revenues: 500)
      member = book_member_fixture(book, balance_config_id: former_balance_config.id)

      {:ok, live, _html} = live(conn, ~p"/books/#{book}/members/#{member}/revenues")

      assert {:ok, _live, html} =
               live
               |> form("form", balance_config: %{revenues: 1500})
               |> render_submit()
               |> follow_redirect(conn, ~p"/books/#{book}/members/#{member}/revenues/transfers")

      assert html =~ "Set revenues"

      # Delete the former balance config, it's not linked to anything anymore
      refute Repo.reload(former_balance_config)

      member = Repo.reload!(member)
      assert balance_config = Repo.get(BalanceConfig, member.balance_config_id)
      assert balance_config.owner_id == user.id
      assert balance_config.revenues == 1500
    end

    test "validates the revenues", %{conn: conn, book: book} do
      member = book_member_fixture(book)

      {:ok, live, _html} = live(conn, ~p"/books/#{book}/members/#{member}/revenues")

      assert html =
               live
               |> form("form", balance_config: %{revenues: -1})
               |> render_submit()

      assert html =~ "must be greater than or equal to 0"
    end

    test "displays a message when there is no current balance config", %{conn: conn, book: book} do
      member = book_member_fixture(book)

      {:ok, _live, html} = live(conn, ~p"/books/#{book}/members/#{member}/revenues")

      assert html =~ "This member revenues were not set yet."
    end

    test "displays a message when the user is the owner of the balance config", %{
      conn: conn,
      book: book,
      user: user
    } do
      balance_config = balance_config_fixture(owner_id: user.id, revenues: 6543)
      member = book_member_fixture(book, balance_config_id: balance_config.id)

      {:ok, _live, html} = live(conn, ~p"/books/#{book}/members/#{member}/revenues")

      assert html =~ "This is the current revenues of the member"
      assert html =~ "6543"
    end

    test "displays a message when the user is not the owner of the balance config", %{
      conn: conn,
      book: book
    } do
      balance_config = balance_config_fixture()
      member = book_member_fixture(book, balance_config_id: balance_config.id)

      {:ok, _live, html} = live(conn, ~p"/books/#{book}/members/#{member}/revenues")

      assert html =~
               "You cannot see the current revenues of this member, but you are allowed to change them."
    end
  end
end
