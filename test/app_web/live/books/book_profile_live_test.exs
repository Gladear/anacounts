defmodule AppWeb.BookProfileLiveTest do
  use AppWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import App.Books.MembersFixtures
  import App.BooksFixtures

  setup :register_and_log_in_user

  setup %{user: user} do
    book = book_fixture()

    member =
      book_member_fixture(book,
        user_id: user.id,
        nickname: "MemberNickname",
        inserted_at: ~N[2022-10-05 12:00:00]
      )

    {:ok, book: book, member: member}
  end

  describe "Balance card" do
    test "shows the balance of the member", %{conn: conn, book: book} do
      {:ok, _live, html} = live(conn, ~p"/books/#{book.id}/profile")

      balance_text =
        html
        |> Floki.parse_document!()
        |> Floki.find("[href='/books/#{book.id}/balance']")
        |> Floki.text()

      assert balance_text =~ "Balance"
      assert balance_text =~ "€0.00"
    end

    test "navigates to the balance page", %{conn: conn, book: book} do
      {:ok, live, _html} = live(conn, ~p"/books/#{book.id}/profile")

      assert {:ok, _live, html} =
               live
               |> element("[href='/books/#{book.id}/balance']", "Balance")
               |> render_click()
               |> follow_redirect(conn, ~p"/books/#{book}/balance")

      assert html =~ "Balance"
    end
  end

  describe "Joined on card" do
    test "shows the date the member was created", %{conn: conn, member: member} do
      {:ok, _live, html} = live(conn, ~p"/books/#{member.book_id}/profile")

      assert html =~ "Joined on"
      assert html =~ "05-10-2022"
    end
  end

  describe "Set revenues card" do
    test "navigates to the Set revenues page", %{conn: conn, book: book} do
      {:ok, live, _html} = live(conn, ~p"/books/#{book.id}/profile")

      assert {:ok, _live, html} =
               live
               |> element("[href='/books/#{book.id}/profile/revenues']", "Set revenues")
               |> render_click()
               |> follow_redirect(conn, ~p"/books/#{book}/profile/revenues")

      assert html =~ "Set revenues"
    end
  end

  describe "Change nickname card" do
    test "navigates to the nickname change page", %{conn: conn, book: book} do
      {:ok, live, _html} = live(conn, ~p"/books/#{book}/profile")

      assert {:ok, _live, html} =
               live
               |> element(
                 "[href='/books/#{book.id}/profile/nickname']",
                 "Change nickname"
               )
               |> render_click()
               |> follow_redirect(conn, ~p"/books/#{book}/profile/nickname")

      assert html =~ "Change nickname"
    end
  end

  describe "Go to my account card" do
    test "navigates to the My account page", %{conn: conn, book: book} do
      {:ok, live, _html} = live(conn, ~p"/books/#{book.id}/profile")

      assert {:ok, _live, html} =
               live
               |> element("[href='/users/settings']", "Go to my account")
               |> render_click()
               |> follow_redirect(conn, ~p"/users/settings")

      assert html =~ "My account"
    end
  end
end
