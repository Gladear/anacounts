defmodule AppWeb.BookBalanceLiveTest do
  use AppWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import App.Balance.BalanceConfigsFixtures
  import App.Books.MembersFixtures
  import App.BooksFixtures
  import App.TransfersFixtures

  setup [:register_and_log_in_user]

  setup %{user: user} do
    book = book_fixture()
    member = book_member_fixture(book, user_id: user.id, nickname: "Me")

    %{book: book, member: member}
  end

  test "shows the current member balance", %{conn: conn, book: book, member: member} do
    other_member = book_member_fixture(book, nickname: "Other Member")

    transfer =
      money_transfer_fixture(book, tenant_id: member.id, amount: Money.new!(:EUR, "100.00"))

    _peer = peer_fixture(transfer, member_id: member.id)
    _peer = peer_fixture(transfer, member_id: other_member.id)

    {:ok, _live, html} = live(conn, ~p"/books/#{book}/balance")

    card_text =
      html
      |> LazyHTML.from_fragment()
      |> LazyHTML.query(".card-grid .card:nth-child(1)")
      |> LazyHTML.text()

    assert card_text =~ "Balance"
    assert card_text =~ "€50.00"
  end

  test "links to manual creation of reimbursements", %{conn: conn, book: book} do
    {:ok, _live, html} = live(conn, ~p"/books/#{book}/balance")

    card_text =
      html
      |> LazyHTML.from_fragment()
      |> LazyHTML.query(".card-grid a:nth-child(2)")
      |> LazyHTML.text()

    assert card_text =~ "Manual reimbursement"
  end

  test "shows the transactions required to balance the book", %{
    conn: conn,
    book: book,
    member: member
  } do
    other_member = book_member_fixture(book, nickname: "You")

    transfer =
      money_transfer_fixture(book, tenant_id: member.id, amount: Money.new!(:EUR, "100.00"))

    _peer = peer_fixture(transfer, member_id: member.id)
    _peer = peer_fixture(transfer, member_id: other_member.id)

    {:ok, _live, html} = live(conn, ~p"/books/#{book}/balance")

    # Ensure there's only one tile
    [tile_link] =
      html
      |> LazyHTML.from_fragment()
      |> LazyHTML.query_by_id("transactions")
      |> LazyHTML.child_nodes()
      |> Enum.to_list()

    expected_href =
      ~p"/books/#{book}/reimbursements/new?from=#{other_member.id}&to=#{member.id}&amount=%E2%82%AC50.00"

    assert LazyHTML.attribute(tile_link, "href") == [expected_href]

    tile_text = LazyHTML.text(tile_link)
    assert tile_text =~ "You"
    assert tile_text =~ "owes"
    assert tile_text =~ "Me"
    assert tile_text =~ "€50.00"
    assert tile_text =~ "Settle up"
  end

  test "shows the errors when information is missing", %{conn: conn, book: book, member: member} do
    other_member = book_member_fixture(book, nickname: "You")

    transfer =
      money_transfer_fixture(book,
        tenant_id: member.id,
        amount: Money.new!(:EUR, "100.00"),
        balance_means: :weight_by_revenues
      )

    balance_config = member_balance_config_fixture(member)
    _peer = peer_fixture(transfer, member_id: member.id, balance_config_id: balance_config.id)
    _peer = peer_fixture(transfer, member_id: other_member.id)

    {:ok, _live, html} = live(conn, ~p"/books/#{book}/balance")

    assert html =~ "Some information is missing to balance the book"

    # Ensure there's only one tile
    [tile_link] =
      html
      |> LazyHTML.from_fragment()
      |> LazyHTML.query_by_id("transaction-errors")
      |> LazyHTML.query("a")
      |> Enum.to_list()

    expected_href = ~p"/books/#{book}/members/#{other_member.id}"
    assert LazyHTML.attribute(tile_link, "href") == [expected_href]

    tile_text = LazyHTML.text(tile_link)
    assert tile_text =~ "You"
    assert tile_text =~ "did not set their revenues."
    assert tile_text =~ "Fix it"
  end
end
