defmodule App.TransfersTest do
  use App.DataCase, async: true

  import App.AccountsFixtures
  import App.Balance.BalanceConfigsFixtures
  import App.Books.MembersFixtures
  import App.BooksFixtures
  import App.TransfersFixtures

  alias App.Repo

  alias App.Books.Book
  alias App.Books.BookMember
  alias App.Transfers
  alias App.Transfers.MoneyTransfer
  alias App.Transfers.Peer

  describe "list_transfers_of_book/2" do
    setup :book_with_member_context

    test "lists all transfers in book", %{book: book, member: member} do
      transfer = money_transfer_fixture(book, tenant_id: member.id)

      assert [found_transfer] = Transfers.list_transfers_of_book(book)
      assert found_transfer.id == transfer.id
    end

    test "sorts by most recent", %{book: book, member: member} do
      transfer1 = money_transfer_fixture(book, date: ~D[2020-06-29], tenant_id: member.id)
      transfer2 = money_transfer_fixture(book, date: ~D[2020-06-30], tenant_id: member.id)

      assert Transfers.list_transfers_of_book(book, filters: %{sort_by: :most_recent})
             |> Enum.map(& &1.id) == [transfer2.id, transfer1.id]
    end

    test "sorts by oldest", %{book: book, member: member} do
      transfer1 = money_transfer_fixture(book, date: ~D[2020-06-29], tenant_id: member.id)
      transfer2 = money_transfer_fixture(book, date: ~D[2020-06-30], tenant_id: member.id)

      assert Transfers.list_transfers_of_book(book, filters: %{sort_by: :oldest})
             |> Enum.map(& &1.id) == [transfer1.id, transfer2.id]
    end

    test "sorts by last created", %{book: book, member: member} do
      transfer1 =
        money_transfer_fixture(book, inserted_at: ~N[2020-06-29 12:00:00], tenant_id: member.id)

      transfer2 =
        money_transfer_fixture(book, inserted_at: ~N[2020-06-30 12:00:00], tenant_id: member.id)

      assert Transfers.list_transfers_of_book(book, filters: %{sort_by: :last_created})
             |> Enum.map(& &1.id) == [transfer2.id, transfer1.id]
    end

    test "sorts by first created", %{book: book, member: member} do
      transfer1 =
        money_transfer_fixture(book, inserted_at: ~N[2020-06-29 12:00:00], tenant_id: member.id)

      transfer2 =
        money_transfer_fixture(book, inserted_at: ~N[2020-06-30 12:00:00], tenant_id: member.id)

      assert Transfers.list_transfers_of_book(book, filters: %{sort_by: :first_created})
             |> Enum.map(& &1.id) == [transfer1.id, transfer2.id]
    end

    test "filters by tenanted by anyone", %{book: book} do
      member1 = book_member_fixture(book)
      transfer1 = money_transfer_fixture(book, tenant_id: member1.id)

      member2 = book_member_fixture(book)
      transfer2 = money_transfer_fixture(book, tenant_id: member2.id)

      assert Transfers.list_transfers_of_book(book, filters: %{tenanted_by: nil})
             |> Enum.map(& &1.id)
             |> Enum.sort() == [transfer1.id, transfer2.id]
    end

    test "filters by tenanted by member", %{book: book} do
      member1 = book_member_fixture(book)
      transfer1 = money_transfer_fixture(book, tenant_id: member1.id)

      member2 = book_member_fixture(book)
      _transfer2 = money_transfer_fixture(book, tenant_id: member2.id)

      assert Transfers.list_transfers_of_book(book, filters: %{tenanted_by: member1.id})
             |> Enum.map(& &1.id) == [transfer1.id]
    end

    test "filters by tenanted by not member", %{book: book} do
      member1 = book_member_fixture(book)
      _transfer1 = money_transfer_fixture(book, tenant_id: member1.id)

      member2 = book_member_fixture(book)
      transfer2 = money_transfer_fixture(book, tenant_id: member2.id)

      assert Transfers.list_transfers_of_book(book, filters: %{tenanted_by: {:not, member1.id}})
             |> Enum.map(& &1.id) == [transfer2.id]
    end

    test "filters by creator", %{book: book} do
      member1 = book_member_fixture(book)
      member2 = book_member_fixture(book)
      member3 = book_member_fixture(book)

      transfer1 = money_transfer_fixture(book, tenant_id: member1.id, creator_id: member1.id)
      transfer2 = money_transfer_fixture(book, tenant_id: member1.id, creator_id: member2.id)

      assert Transfers.list_transfers_of_book(book, filters: %{created_by: [member1.id]})
             |> Enum.map(& &1.id) == [transfer1.id]

      assert Transfers.list_transfers_of_book(book, filters: %{created_by: [member2.id]})
             |> Enum.map(& &1.id) == [transfer2.id]

      assert Transfers.list_transfers_of_book(book, filters: %{created_by: [member3.id]}) == []
    end

    test "paginates results", %{book: book, member: member} do
      transfer1 = money_transfer_fixture(book, tenant_id: member.id, date: ~D[2020-06-29])
      transfer2 = money_transfer_fixture(book, tenant_id: member.id, date: ~D[2020-06-30])

      assert Transfers.list_transfers_of_book(book, offset: 0, limit: 1)
             |> Enum.map(& &1.id) == [transfer2.id]

      assert Transfers.list_transfers_of_book(book, offset: 1, limit: 1)
             |> Enum.map(& &1.id) == [transfer1.id]

      assert Transfers.list_transfers_of_book(book, offset: 0, limit: 25)
             |> Enum.map(& &1.id) == [transfer2.id, transfer1.id]
    end

    test "paginated results are filtered and consistent", %{book: book} do
      member1 = book_member_fixture(book)
      member2 = book_member_fixture(book)

      transfer1 = money_transfer_fixture(book, tenant_id: member1.id, date: ~D[2020-06-29])
      _transfer2 = money_transfer_fixture(book, tenant_id: member1.id, date: ~D[2020-06-30])
      transfer3 = money_transfer_fixture(book, tenant_id: member2.id, date: ~D[2020-06-28])

      assert Transfers.list_transfers_of_book(book,
               filters: %{tenanted_by: member2.id},
               offset: 0,
               limit: 25
             )
             |> Enum.map(& &1.id) == [transfer3.id]

      assert Transfers.list_transfers_of_book(book,
               filters: %{tenanted_by: {:not, member2.id}},
               offset: 1,
               limit: 25
             )
             |> Enum.map(& &1.id) == [transfer1.id]
    end

    test "paginated results are sorted and consistent", %{book: book, member: member} do
      transfer1 =
        money_transfer_fixture(book,
          tenant_id: member.id,
          date: ~D[2020-06-29],
          inserted_at: ~N[2020-06-29 12:00:00]
        )

      transfer2 =
        money_transfer_fixture(book,
          tenant_id: member.id,
          date: ~D[2020-06-30],
          inserted_at: ~N[2020-06-30 12:00:00]
        )

      transfer3 =
        money_transfer_fixture(book,
          tenant_id: member.id,
          date: ~D[2020-06-28],
          inserted_at: ~N[2020-06-28 12:00:00]
        )

      assert Transfers.list_transfers_of_book(book,
               filters: %{sort_by: :most_recent},
               offset: 0,
               limit: 25
             )
             |> Enum.map(& &1.id) == [transfer2.id, transfer1.id, transfer3.id]

      assert Transfers.list_transfers_of_book(book,
               filters: %{sort_by: :oldest},
               offset: 2,
               limit: 25
             )
             |> Enum.map(& &1.id) == [transfer2.id]

      assert Transfers.list_transfers_of_book(book,
               filters: %{sort_by: :last_created},
               offset: 1,
               limit: 25
             )
             |> Enum.map(& &1.id) == [transfer1.id, transfer3.id]
    end
  end

  describe "list_transfers_of_members/1" do
    setup do
      %{book: book_fixture()}
    end

    test "lists all transfers linked to members", %{book: book} do
      member1 = book_member_fixture(book)
      member2 = book_member_fixture(book)

      transfer1 = money_transfer_fixture(book, tenant_id: member1.id)
      _peer = peer_fixture(transfer1, member_id: member2.id)

      transfer2 = money_transfer_fixture(book, tenant_id: member2.id)

      _peer = peer_fixture(transfer2, member_id: member1.id)
      _peer = peer_fixture(transfer2, member_id: member2.id)

      assert Transfers.list_transfers_of_members([member1, member2])
             |> Enum.map(& &1.id)
             |> Enum.sort() == [transfer1.id, transfer2.id]
    end
  end

  describe "create_money_transfer/4" do
    setup :book_with_member_context

    test "creates a money transfer", %{book: book, member: member} do
      assert {:ok, transfer} =
               Transfers.create_money_transfer(
                 book,
                 member,
                 :payment,
                 money_transfer_attributes(
                   tenant_id: member.id,
                   label: "A label",
                   amount: Money.new!(:EUR, 1799),
                   date: ~D[2022-06-23]
                 )
               )

      assert transfer.label == "A label"
      assert transfer.amount == Money.new!(:EUR, 1799)
      assert transfer.type == :payment
      assert transfer.date == ~D[2022-06-23]
      assert transfer.balance_means == :divide_equally
      assert transfer.creator_id == member.id

      transfer = Repo.preload(transfer, :peers)
      assert Enum.empty?(transfer.peers)
    end

    test "sets balance means", %{book: book, member: member} do
      assert {:ok, transfer} =
               Transfers.create_money_transfer(
                 book,
                 member,
                 :payment,
                 money_transfer_attributes(
                   tenant_id: member.id,
                   balance_means: :weight_by_revenues
                 )
               )

      assert transfer.balance_means == :weight_by_revenues
    end

    test "creates peers along the way", %{book: book, member: member} do
      other_user = user_fixture()
      balance_config = balance_config_fixture()

      other_member =
        book_member_fixture(book, user_id: other_user.id, balance_config_id: balance_config.id)

      assert {:ok, transfer} =
               Transfers.create_money_transfer(
                 book,
                 member,
                 :payment,
                 money_transfer_attributes(
                   tenant_id: member.id,
                   peers: [
                     %{member_id: member.id},
                     %{member_id: other_member.id, weight: Decimal.new(3)}
                   ]
                 )
               )

      peer1 = Repo.get_by!(Peer, transfer_id: transfer.id, member_id: member.id)
      peer2 = Repo.get_by!(Peer, transfer_id: transfer.id, member_id: other_member.id)

      assert peer1.member_id == member.id
      assert peer1.balance_config_id == nil
      assert peer2.member_id == other_member.id
      assert peer2.balance_config_id == balance_config.id
      assert peer2.weight == Decimal.new(3)
    end

    test "cannot create two peers for the same member", %{book: book, member: member} do
      assert_raise Ecto.ConstraintError, ~r/transfers_peers_transfer_id_member_id_index/, fn ->
        Transfers.create_money_transfer(
          book,
          member,
          :payment,
          money_transfer_attributes(
            tenant_id: member.id,
            peers: [%{member_id: member.id}, %{member_id: member.id}]
          )
        )
      end
    end

    test "fails with invalid book_id", %{member: member} do
      assert_raise Ecto.ConstraintError, ~r/money_transfers_book_id_fkey/, fn ->
        Transfers.create_money_transfer(
          %Book{id: 0},
          member,
          :payment,
          money_transfer_attributes(tenant_id: member.id)
        )
      end
    end

    test "fails with invalid creator_id", %{book: book, member: member} do
      assert_raise Ecto.ConstraintError, ~r/money_transfers_creator_id_fkey/, fn ->
        Transfers.create_money_transfer(
          book,
          %BookMember{id: 0},
          :payment,
          money_transfer_attributes(tenant_id: member.id)
        )
      end
    end

    test "fails with invalid type", %{book: book, member: member} do
      assert_raise FunctionClauseError, fn ->
        Transfers.create_money_transfer(
          book,
          member,
          :reimbursement,
          money_transfer_attributes(tenant_id: member.id)
        )
      end
    end

    test "fails with missing tenant_id", %{book: book, member: member} do
      assert {:error, changeset} =
               Transfers.create_money_transfer(
                 book,
                 member,
                 :payment,
                 money_transfer_attributes()
               )

      assert errors_on(changeset) == %{tenant_id: ["can't be blank"]}
    end

    test "fails with invalid tenant_id", %{book: book, member: member} do
      assert {:error, changeset} =
               Transfers.create_money_transfer(
                 book,
                 member,
                 :payment,
                 money_transfer_attributes(tenant_id: 0)
               )

      assert errors_on(changeset) == %{tenant_id: ["does not exist"]}
    end
  end

  describe "update_money_transfer/2" do
    setup :book_with_member_context
    setup :money_transfer_in_book_context

    test "updates the money transfer", %{book: book, money_transfer: money_transfer} do
      other_user = user_fixture()
      other_member = book_member_fixture(book, user_id: other_user.id)

      assert {:ok, updated} =
               money_transfer
               |> Repo.preload(:peers)
               |> Transfers.update_money_transfer(%{
                 label: "my very own label !",
                 amount: Money.new!(:EUR, 299),
                 date: ~D[2020-06-29],
                 balance_means: :weight_by_revenues,
                 peers: [%{member_id: other_member.id}]
               })

      assert updated.label == "my very own label !"
      assert updated.amount == Money.new!(:EUR, 299)
      assert updated.date == ~D[2020-06-29]
      assert updated.balance_means == :weight_by_revenues

      assert [peer] = updated.peers
      assert peer.member_id == other_member.id
    end

    test "does not update book", %{book: book, money_transfer: money_transfer} do
      other_book = book_fixture()

      assert {:ok, updated} =
               Transfers.update_money_transfer(money_transfer, %{
                 book_id: other_book.id
               })

      assert updated.book_id == book.id
    end

    test "updates existing peers", %{book: book, member: member} do
      money_transfer = money_transfer_fixture(book, tenant_id: member.id)
      peer = peer_fixture(money_transfer, member_id: member.id, weight: Decimal.new(2))

      assert {:ok, updated_transfer} =
               money_transfer
               |> Repo.preload(:peers)
               |> Transfers.update_money_transfer(%{
                 peers: [%{id: peer.id, member_id: member.id, weight: Decimal.new(3)}]
               })

      assert [updated_peer] = updated_transfer.peers
      assert updated_peer.id == peer.id
      assert updated_peer.member_id == member.id
      assert updated_peer.weight == Decimal.new(3)
    end

    test "deletes peers", %{book: book, member: member} do
      money_transfer = money_transfer_fixture(book, tenant_id: member.id)
      _peer = peer_fixture(money_transfer, member_id: member.id)

      assert {:ok, updated_transfer} =
               money_transfer
               |> Repo.preload(:peers)
               |> Transfers.update_money_transfer(%{
                 peers: []
               })

      assert Enum.empty?(updated_transfer.peers)
    end

    test "cannot create two peers for the same member", %{
      member: member,
      money_transfer: money_transfer
    } do
      assert_raise Ecto.ConstraintError, ~r/transfers_peers_transfer_id_member_id_index/, fn ->
        money_transfer
        |> Repo.preload(:peers)
        |> Transfers.update_money_transfer(%{
          peers: [%{member_id: member.id}, %{member_id: member.id}]
        })
      end
    end
  end

  describe "delete_money_transfer/1" do
    setup :book_with_member_context
    setup :money_transfer_in_book_context

    test "deletes the money transfer", %{money_transfer: money_transfer} do
      assert {:ok, deleted_transfer} = Transfers.delete_money_transfer(money_transfer)
      assert deleted_transfer.id == money_transfer.id
    end

    test "deleted related peers", %{book: book, member: member} do
      money_transfer = money_transfer_fixture(book, tenant_id: member.id)
      _peer = peer_fixture(money_transfer, member_id: member.id)

      assert {:ok, _deleted_transfer} = Transfers.delete_money_transfer(money_transfer)

      refute Repo.get_by(Peer, transfer_id: money_transfer.id)
    end
  end

  describe "create_reimbursement/2" do
    setup do
      book = book_fixture()
      member1 = book_member_fixture(book)
      member2 = book_member_fixture(book)

      %{book: book, member1: member1, member2: member2}
    end

    test "creates a reimbursement in a book", %{book: book, member1: member1, member2: member2} do
      assert {:ok, money_transfer} =
               Transfers.create_reimbursement(book, %{
                 label: "Reimbursement from member1 to member2",
                 amount: Money.new!(:EUR, 100),
                 date: ~D[2020-06-29],
                 tenant_id: member1.id,
                 peers: [%{member_id: member2.id}]
               })

      assert money_transfer.label == "Reimbursement from member1 to member2"
      assert money_transfer.amount == Money.new!(:EUR, 100)
      assert money_transfer.type == :reimbursement
      assert money_transfer.date == ~D[2020-06-29]
      assert money_transfer.tenant_id == member1.id
      assert money_transfer.balance_means == :divide_equally
    end

    test "cannot create a payment or an income", %{book: book, member1: member1, member2: member2} do
      assert {:ok, money_transfer} =
               Transfers.create_reimbursement(
                 book,
                 money_transfer_attributes(
                   type: :payment,
                   tenant_id: member1.id,
                   peers: [%{member_id: member2.id}]
                 )
               )

      assert money_transfer.type == :reimbursement
    end

    test "cannot create a money transfer weighted by income", %{
      book: book,
      member1: member1,
      member2: member2
    } do
      assert {:ok, money_transfer} =
               Transfers.create_reimbursement(
                 book,
                 money_transfer_attributes(
                   balance_means: :weighted_by_income,
                   tenant_id: member1.id,
                   peers: [%{member_id: member2.id, weight: Decimal.new(3)}]
                 )
               )

      assert money_transfer.balance_means == :divide_equally
    end

    test "cannot create a money transfer withour peers", %{book: book, member1: member1} do
      assert_raise Ecto.ChangeError, "A reimbursement must have exactly one peer", fn ->
        Transfers.create_reimbursement(
          book,
          money_transfer_attributes(
            tenant_id: member1.id,
            peers: []
          )
        )
      end
    end

    test "cannot create a money transfer with multiple peers", %{book: book, member1: member1} do
      member2 = book_member_fixture(book)
      member3 = book_member_fixture(book)

      assert_raise Ecto.ChangeError, "A reimbursement must have exactly one peer", fn ->
        Transfers.create_reimbursement(
          book,
          money_transfer_attributes(
            tenant_id: member1.id,
            peers: [%{member_id: member2.id}, %{member_id: member3.id}]
          )
        )
      end
    end

    test "cannot create a money transfer with the only peer being the tenant", %{
      book: book,
      member1: member1
    } do
      assert {:error, changeset} =
               Transfers.create_reimbursement(
                 book,
                 money_transfer_attributes(
                   tenant_id: member1.id,
                   peers: [%{member_id: member1.id}]
                 )
               )

      assert errors_on(changeset) == %{
               tenant_id: ["cannot be the same as the debtor"]
             }
    end
  end

  describe "change_reimbursement/2" do
    test "creates a reimbursement changeset" do
      assert %Ecto.Changeset{} = Transfers.change_reimbursement(%MoneyTransfer{})
    end

    test "cannot change the type of the transfer" do
      changeset = Transfers.change_reimbursement(%MoneyTransfer{}, %{type: :payment})

      assert Ecto.Changeset.fetch_change(changeset, :type) == :error
    end
  end

  defp book_with_member_context(_context) do
    book = book_fixture()
    user = user_fixture()
    member = book_member_fixture(book, user_id: user.id)

    %{
      book: book,
      user: user,
      member: member
    }
  end

  # Depends on :book_with_member_context
  defp money_transfer_in_book_context(%{book: book, member: member}) do
    %{money_transfer: money_transfer_fixture(book, tenant_id: member.id)}
  end
end
