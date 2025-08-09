defmodule AppWeb.BookLiveTest do
  use AppWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import App.Balance.BalanceConfigsFixtures
  import App.Books.MembersFixtures
  import App.BooksFixtures
  import App.TransfersFixtures

  setup :register_and_log_in_user

  setup %{user: user} do
    book = book_fixture()
    member = book_member_fixture(book, user_id: user.id, nickname: "MemberNickname")
    {:ok, book: book, member: member}
  end

  test "cannot be accessed by non-members", %{conn: conn} do
    book = book_fixture()

    assert_raise Ecto.NoResultsError, fn ->
      live(conn, ~p"/books/#{book.id}")
    end
  end

  describe "Revenues alert" do
    test "is shown when them member incomes are not set", %{conn: conn, book: book} do
      {:ok, _live, html} = live(conn, ~p"/books/#{book}")

      assert html =~ "Your revenues are not set"
    end

    test "is hidden when them member incomes are set", %{conn: conn, book: book, member: member} do
      _balance_config = member_balance_config_fixture(member, revenues: 1234)

      {:ok, _live, html} = live(conn, ~p"/books/#{book}")

      refute html =~ "Your revenues are not set"
    end
  end

  describe "My profile card" do
    test "shows the member nickname", %{conn: conn, book: book, member: member} do
      {:ok, _live, html} = live(conn, ~p"/books/#{book}")

      assert html =~ member.nickname
    end

    test "navigates to the member profile", %{conn: conn, book: book, member: member} do
      {:ok, live, _html} = live(conn, ~p"/books/#{book}")

      assert {:ok, _, html} =
               live
               |> element("[href='/books/#{book.id}/profile']", member.nickname)
               |> render_click()
               |> follow_redirect(conn, ~p"/books/#{book}/profile")

      assert html =~ member.nickname
    end
  end

  describe "Balance card" do
    test "shows the member balance", %{conn: conn, book: book} do
      {:ok, _live, html} = live(conn, ~p"/books/#{book}")

      assert html =~ "€0.00"
    end

    test "navigates to the book balance", %{conn: conn, book: book} do
      {:ok, live, _html} = live(conn, ~p"/books/#{book}")

      assert {:ok, _, html} =
               live
               |> element("[href='/books/#{book.id}/balance']", "Balance")
               |> render_click()
               |> follow_redirect(conn, ~p"/books/#{book}/balance")

      assert html =~ "Balance"
    end
  end

  describe "Latest transfers card" do
    test "shows the 5 last created transfers", %{conn: conn, book: book, member: member} do
      invisible_transfer =
        money_transfer_fixture(book,
          label: "Housing",
          tenant_id: member.id,
          inserted_at: ~N[2021-01-01 00:00:00Z]
        )

      visible_labels = [
        "Food",
        "Car fuel",
        "Overcharge",
        "Reimbursement #1",
        "Reimbursement #2"
      ]

      _visible_transfers =
        for label <- visible_labels do
          money_transfer_fixture(book,
            label: label,
            tenant_id: member.id,
            inserted_at: ~N[2021-01-02 00:00:00Z]
          )
        end

      {:ok, _live, html} = live(conn, ~p"/books/#{book}")

      for label <- visible_labels do
        assert html =~ label
      end

      refute html =~ invisible_transfer.label
    end

    test "navigates to the book transfers", %{conn: conn, book: book} do
      {:ok, live, _html} = live(conn, ~p"/books/#{book}")

      assert {:ok, _, html} =
               live
               |> element("[href='/books/#{book.id}/transfers']", "Latest transfers")
               |> render_click()
               |> follow_redirect(conn, ~p"/books/#{book}/transfers")

      assert html =~ "Transfers"
    end
  end

  describe "New payment card" do
    test "navigates to the new payment form", %{conn: conn, book: book} do
      {:ok, live, _html} = live(conn, ~p"/books/#{book}")

      assert {:ok, _, html} =
               live
               |> element("[href='/books/#{book.id}/transfers/new']", "New payment")
               |> render_click()
               |> follow_redirect(conn, ~p"/books/#{book}/transfers/new")

      assert html =~ "New payment"
    end
  end

  describe "Members card" do
    test "show the number of members in the book", %{conn: conn, book: book} do
      _member2 = book_member_fixture(book, nickname: "Member2")
      _member3 = book_member_fixture(book, nickname: "Member3")

      {:ok, _live, html} = live(conn, ~p"/books/#{book}")

      member_card_text =
        html
        |> Floki.parse_document!()
        |> Floki.find("[href='/books/#{book.id}/members']")
        |> Floki.text()

      assert member_card_text =~ "3"
      assert member_card_text =~ "2 unlinked"
    end

    test "navigates to the book members", %{conn: conn, book: book} do
      {:ok, live, _html} = live(conn, ~p"/books/#{book}")

      assert {:ok, _, html} =
               live
               |> element("[href='/books/#{book.id}/members']", "Members")
               |> render_click()
               |> follow_redirect(conn, ~p"/books/#{book}/members")

      assert html =~ "Members"
    end
  end

  describe "Configuration card" do
    test "navigates to the book configuration page", %{conn: conn, book: book} do
      {:ok, live, _html} = live(conn, ~p"/books/#{book}")

      assert {:ok, _, html} =
               live
               |> element("[href='/books/#{book.id}/configuration']", "Configuration")
               |> render_click()
               |> follow_redirect(conn, ~p"/books/#{book}/configuration")

      assert html =~ "Configuration"
    end
  end
end
