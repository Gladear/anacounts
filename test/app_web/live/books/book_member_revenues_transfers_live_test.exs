defmodule AppWeb.BookMemberRevenuesTransfersLiveTest do
  use AppWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import App.Balance.BalanceConfigsFixtures
  import App.BooksFixtures
  import App.Books.MembersFixtures
  import App.TransfersFixtures

  alias App.Repo

  setup :register_and_log_in_user

  setup %{user: user} do
    book = book_fixture()
    balance_config = balance_config_fixture()
    member = book_member_fixture(book, user_id: user.id, balance_config_id: balance_config.id)

    %{book: book, member: member, balance_config: balance_config}
  end

  describe "/books/:book_id/profile/revenues/transfers" do
    test "show the form with the member transfers", %{
      conn: conn,
      book: book,
      member: member,
      balance_config: balance_config
    } do
      transfer1 = money_transfer_fixture(book, tenant_id: member.id, date: ~D[2020-01-01])
      peer1 = peer_fixture(transfer1, member_id: member.id, balance_config_id: balance_config.id)

      transfer2 = money_transfer_fixture(book, tenant_id: member.id, date: ~D[2020-01-02])
      # no balance config, so the transfer checkbox and disabled and forced checked
      peer2 = peer_fixture(transfer2, member_id: member.id)

      # the member isn't a peer, so the transfer isn't shown
      _transfer3 = money_transfer_fixture(book, tenant_id: member.id, date: ~D[2020-01-03])

      {:ok, _live, html} = live(conn, ~p"/books/#{book}/profile/revenues/transfers")

      assert html =~ "Set revenues"

      inputs =
        html
        |> Floki.parse_document!()
        |> Floki.find("input")

      assert [transfer2_hidden, transfer2_checkbox, transfer1_checkbox] = inputs

      assert Floki.attribute(transfer1_checkbox, "value") == ["#{peer1.id}"]
      assert Floki.attribute(transfer2_hidden, "value") == ["#{peer2.id}"]
      assert Floki.attribute(transfer2_checkbox, "checked") == ["checked"]
    end

    test "updates the peers of the selected transfers", %{
      conn: conn,
      book: book,
      member: member,
      balance_config: balance_config
    } do
      transfer1 = money_transfer_fixture(book, tenant_id: member.id, date: ~D[2020-01-01])
      peer1 = peer_fixture(transfer1, member_id: member.id)

      transfer2 = money_transfer_fixture(book, tenant_id: member.id, date: ~D[2020-01-02])
      peer2 = peer_fixture(transfer2, member_id: member.id)

      {:ok, live, _html} = live(conn, ~p"/books/#{book}/profile/revenues/transfers")

      assert {:ok, _live, _html} =
               live
               |> form("form", peer_ids: [peer1.id])
               |> render_submit()
               |> follow_redirect(conn, ~p"/books/#{book}/profile")

      peer1 = Repo.reload(peer1)
      assert peer1.balance_config_id == balance_config.id

      # peer2 was not selected, so it's not updated
      peer2 = Repo.reload(peer2)
      assert peer2.balance_config_id == nil
    end
  end

  describe "/books/:book_id/members/:member_id/revenues/transfers" do
    test "shows the form", %{conn: conn, book: book} do
      member = book_member_fixture(book)

      {:ok, _live, html} = live(conn, ~p"/books/#{book}/members/#{member.id}/revenues/transfers")

      assert html =~ "Set revenues"
      assert html =~ "Transfers"
      assert html =~ "There is no transfer in the book for now."
      assert html =~ "Finish"
    end
  end
end
