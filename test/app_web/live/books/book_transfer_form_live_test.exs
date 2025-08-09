defmodule AppWeb.BookTransferFormLiveTest do
  use AppWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import App.BooksFixtures
  import App.Books.MembersFixtures
  import App.TransfersFixtures

  alias App.Repo
  alias App.Transfers.Peer

  setup [
    :register_and_log_in_user,
    :book_with_member_context,
    :money_transfer_in_book_context
  ]

  test "displays money transfer", %{conn: conn, book: book, money_transfer: money_transfer} do
    {:ok, _form_live, html} = live(conn, ~p"/books/#{book}/transfers/#{money_transfer}/edit")

    assert html =~ "Transfer"
    assert html =~ "<form"
  end

  test "saves new money_transfer", %{conn: conn, book: book} do
    {:ok, form_live, _html} = live(conn, ~p"/books/#{book}/transfers/new")

    assert form_live
           |> form("form",
             money_transfer: %{
               label: nil,
               amount: "-10.10"
             }
           )
           |> render_change() =~ "can&#39;t be blank"

    {:ok, _, html} =
      form_live
      |> form("form",
        money_transfer: %{
          label: "Created transfer",
          amount: "10.60",
          date: "2022-04-08",
          balance_means: "divide_equally"
        }
      )
      |> render_submit()
      |> follow_redirect(conn, ~p"/books/#{book}/transfers")

    assert html =~ "Created transfer"
  end

  test "updates money transfer", %{conn: conn, book: book, money_transfer: money_transfer} do
    {:ok, form_live, _html} = live(conn, ~p"/books/#{book}/transfers/#{money_transfer}/edit")

    assert form_live
           |> form("form",
             money_transfer: %{
               label: nil,
               amount: "-10.10"
             }
           )
           |> render_change() =~ "can&#39;t be blank"

    {:ok, _, html} =
      form_live
      |> form("form",
        money_transfer: %{
          label: "Updated transfer",
          amount: "6.70",
          date: "2022-04-10",
          balance_means: "weight_by_revenues"
        }
      )
      |> render_submit()
      |> follow_redirect(conn, ~p"/books/#{book}/transfers")

    refute html =~ money_transfer.label
    assert html =~ "Updated transfer"
  end

  test "update the peers instead of recreating them", %{conn: conn, book: book} do
    member = book_member_fixture(book)

    money_transfer =
      money_transfer_fixture(book,
        label: "Original transfer name",
        tenant_id: member.id
      )

    peer = peer_fixture(money_transfer, member_id: member.id)

    {:ok, form_live, _html} = live(conn, ~p"/books/#{book}/transfers/#{money_transfer}/edit")

    {:ok, _, html} =
      form_live
      |> form("form",
        money_transfer: %{
          label: "Updated transfer",
          amount: "6.70",
          date: "2022-04-10",
          balance_means: "weight_by_revenues"
        }
      )
      |> render_submit()
      |> follow_redirect(conn, ~p"/books/#{book}/transfers")

    refute html =~ money_transfer.label
    assert html =~ "Updated transfer"

    new_peer_ids =
      Peer
      |> Repo.all()
      |> Enum.map(& &1.id)

    assert [peer.id] == new_peer_ids
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

  # Depends on :book_with_member_context
  defp money_transfer_in_book_context(%{book: book, member: member} = context) do
    Map.put(
      context,
      :money_transfer,
      money_transfer_fixture(book, tenant_id: member.id)
    )
  end
end
