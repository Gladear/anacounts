defmodule AppWeb.BookReimbursementCreationLiveTest do
  use AppWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import App.BooksFixtures
  import App.Books.MembersFixtures

  alias App.Repo
  alias App.Transfers.MoneyTransfer

  setup [:register_and_log_in_user]

  setup %{user: user} do
    book = book_fixture()
    member = book_member_fixture(book, user_id: user.id)

    %{book: book, member: member}
  end

  test "show the form", %{conn: conn, book: book} do
    {:ok, _live, html} = live(conn, ~p"/books/#{book}/reimbursements/new")

    assert html =~ "Manual reimbursement"
    assert html =~ "Label"
    assert html =~ "Create reimbursement"
  end

  test "includes params as default values", %{conn: conn, book: book} do
    member1 = book_member_fixture(book, nickname: "Member 1")
    member2 = book_member_fixture(book, nickname: "Member 2")

    {:ok, _live, html} =
      live(
        conn,
        ~p"/books/#{book}/reimbursements/new?from=#{member1.id}&to=#{member2.id}&amount=%E2%82%AC100.00"
      )

    doc = Floki.parse_document!(html)

    assert input_value(doc, "#reimbursement_label") ==
             "Reimbursement from Member 1 to Member 2"

    assert select_value(doc, "#reimbursement_tenant_id") ==
             to_string(member2.id)

    assert input_value(doc, "#reimbursement_amount") == "100.00"

    assert select_value(doc, "#reimbursement_peer_member_id") ==
             to_string(member1.id)
  end

  defp input_value(document, selector) do
    document
    |> Floki.attribute(selector, "value")
    |> hd()
  end

  defp select_value(document, selector) do
    document
    |> Floki.find(selector)
    |> Floki.attribute("[selected]", "value")
    |> hd()
  end

  test "validates the form", %{conn: conn, book: book, member: member} do
    {:ok, live, _html} = live(conn, ~p"/books/#{book}/reimbursements/new")

    assert html =
             live
             |> form("form",
               reimbursement: %{
                 label: "",
                 tenant_id: member.id,
                 peer_member_id: member.id
               }
             )
             |> render_submit()

    assert html =~ "can&#39;t be blank"
    assert html =~ "cannot be the same as the debtor"
  end

  test "creates a reimbursement", %{conn: conn, book: book} do
    member1 = book_member_fixture(book, nickname: "Member 1")
    member2 = book_member_fixture(book, nickname: "Member 2")

    {:ok, live, _html} = live(conn, ~p"/books/#{book}/reimbursements/new")

    assert {:ok, _live, _html} =
             live
             |> form("form",
               reimbursement: %{
                 label: "Reimbursement from Member 1 to Member 2",
                 tenant_id: member2.id,
                 peer_member_id: member1.id,
                 amount: "100.00",
                 date: "2021-01-01"
               }
             )
             |> render_submit()
             |> follow_redirect(conn, ~p"/books/#{book}/balance")

    assert reimbursement = Repo.get_by(MoneyTransfer, book_id: book.id)
    assert reimbursement.label == "Reimbursement from Member 1 to Member 2"
    assert reimbursement.type == :reimbursement
    assert reimbursement.amount == Money.new(:EUR, "100.00")
  end
end
