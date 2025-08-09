defmodule App.BalanceTest do
  use App.DataCase, async: true

  import App.Balance.BalanceConfigsFixtures
  import App.Books.MembersFixtures
  import App.BooksFixtures
  import App.TransfersFixtures

  alias App.Balance
  alias App.Balance.BalanceError

  describe "fill_members_balance/1" do
    setup do
      %{book: book_fixture()}
    end

    test "balances transfers correctly", %{book: book} do
      member1 = book_member_fixture(book)
      member2 = book_member_fixture(book)

      money_transfer =
        money_transfer_fixture(book,
          amount: Money.new!(:EUR, 10),
          tenant_id: member1.id
        )

      _peer = peer_fixture(money_transfer, member_id: member1.id)
      _peer = peer_fixture(money_transfer, member_id: member2.id)

      [member1, member2] = Balance.fill_members_balance([member1, member2])
      assert Money.equal?(member1.balance, Money.new!(:EUR, 5))
      assert Money.equal?(member2.balance, Money.new!(:EUR, -5))
    end

    test "balances multiple transfers correctly #1", %{book: book} do
      member1 = book_member_fixture(book)
      member2 = book_member_fixture(book)
      member3 = book_member_fixture(book)
      member4 = book_member_fixture(book)

      transfer1 =
        money_transfer_fixture(book,
          amount: Money.new!(:EUR, 400),
          tenant_id: member1.id
        )

      _peer = peer_fixture(transfer1, member_id: member1.id)
      _peer = peer_fixture(transfer1, member_id: member2.id)
      _peer = peer_fixture(transfer1, member_id: member3.id)
      _peer = peer_fixture(transfer1, member_id: member4.id)

      transfer2 =
        money_transfer_fixture(book,
          amount: Money.new!(:EUR, 400),
          tenant_id: member2.id
        )

      _peer = peer_fixture(transfer2, member_id: member1.id)
      _peer = peer_fixture(transfer2, member_id: member2.id)
      _peer = peer_fixture(transfer2, member_id: member3.id)
      _peer = peer_fixture(transfer2, member_id: member4.id)

      [member1, member2, member3, member4] =
        Balance.fill_members_balance([member1, member2, member3, member4])

      assert Money.equal?(member1.balance, Money.new!(:EUR, 200))
      assert Money.equal?(member2.balance, Money.new!(:EUR, 200))
      assert Money.equal?(member3.balance, Money.new!(:EUR, -200))
      assert Money.equal?(member4.balance, Money.new!(:EUR, -200))
    end

    test "balances multiple transfers correctly #2", %{book: book} do
      member1 = book_member_fixture(book)
      member2 = book_member_fixture(book)
      member3 = book_member_fixture(book)

      transfer1 =
        money_transfer_fixture(book,
          amount: Money.new!(:EUR, 300),
          tenant_id: member1.id
        )

      _peer = peer_fixture(transfer1, member_id: member1.id)
      _peer = peer_fixture(transfer1, member_id: member2.id)
      _peer = peer_fixture(transfer1, member_id: member3.id)

      transfer2 =
        money_transfer_fixture(book,
          amount: Money.new!(:EUR, 300),
          tenant_id: member2.id
        )

      _peer = peer_fixture(transfer2, member_id: member1.id)
      _peer = peer_fixture(transfer2, member_id: member2.id)
      _peer = peer_fixture(transfer2, member_id: member3.id)

      [member1, member2, member3] = Balance.fill_members_balance([member1, member2, member3])
      assert Money.equal?(member1.balance, Money.new!(:EUR, 100))
      assert Money.equal?(member2.balance, Money.new!(:EUR, 100))
      assert Money.equal?(member3.balance, Money.new!(:EUR, -200))
    end

    test "takes peer weight into account", %{book: book} do
      member1 = book_member_fixture(book)
      member2 = book_member_fixture(book)
      member3 = book_member_fixture(book)

      transfer =
        money_transfer_fixture(book,
          tenant_id: member1.id,
          amount: Money.new!(:EUR, 6)
        )

      _peer = peer_fixture(transfer, member_id: member1.id, weight: 3)
      _peer = peer_fixture(transfer, member_id: member2.id, weight: 2)
      _peer = peer_fixture(transfer, member_id: member3.id)

      [member1, member2, member3] = Balance.fill_members_balance([member1, member2, member3])
      assert Money.equal?(member1.balance, Money.new!(:EUR, 3))
      assert Money.equal?(member2.balance, Money.new!(:EUR, -2))
      assert Money.equal?(member3.balance, Money.new!(:EUR, -1))
    end

    test "balances correctly when using high weight", %{book: book} do
      member1 = book_member_fixture(book)
      member2 = book_member_fixture(book)
      member3 = book_member_fixture(book)

      transfer = money_transfer_fixture(book, tenant_id: member1.id, amount: Money.new!(:EUR, 10))

      _peer1 = peer_fixture(transfer, member_id: member1.id, weight: Decimal.new(10))
      _peer2 = peer_fixture(transfer, member_id: member2.id, weight: Decimal.new(10))
      _peer3 = peer_fixture(transfer, member_id: member3.id, weight: Decimal.new(10))

      [member1, member2, member3] = Balance.fill_members_balance([member1, member2, member3])
      assert Money.equal?(member1.balance, Money.new!(:EUR, "6.67"))
      assert Money.equal?(member2.balance, Money.new!(:EUR, "-3.33"))
      assert Money.equal?(member3.balance, Money.new!(:EUR, "-3.34"))
    end

    test "correctly divide non round amounts", %{book: book} do
      member1 = book_member_fixture(book)
      member2 = book_member_fixture(book)

      transfer =
        money_transfer_fixture(book,
          tenant_id: member1.id,
          amount: Money.new!(:EUR, "0.03")
        )

      _peer = peer_fixture(transfer, member_id: member1.id)
      _peer = peer_fixture(transfer, member_id: member2.id)

      assert Balance.fill_members_balance([member1, member2]) == [
               %{member1 | balance: Money.new!(:EUR, "0.02")},
               %{member2 | balance: Money.new!(:EUR, "-0.02")}
             ]
    end

    test "weight transfer amount using peers income #1", %{book: book} do
      member1 = book_member_fixture(book)
      balance_config1 = member_balance_config_fixture(member1, revenues: 1)

      member2 = book_member_fixture(book)
      balance_config2 = member_balance_config_fixture(member2, revenues: 2)

      transfer =
        money_transfer_fixture(book,
          tenant_id: member1.id,
          balance_means: :weight_by_revenues,
          amount: Money.new!(:EUR, 30)
        )

      _peer = peer_fixture(transfer, member_id: member1.id, balance_config_id: balance_config1.id)
      _peer = peer_fixture(transfer, member_id: member2.id, balance_config_id: balance_config2.id)

      [member1, member2] = Balance.fill_members_balance([member1, member2])

      assert Money.equal?(member1.balance, Money.new!(:EUR, 20))
      assert Money.equal?(member2.balance, Money.new!(:EUR, -20))
    end

    test "weight transfer amount using peers income #2", %{book: book} do
      member1 = book_member_fixture(book)
      balance_config1 = member_balance_config_fixture(member1, revenues: 2)

      member2 = book_member_fixture(book)
      balance_config2 = member_balance_config_fixture(member2, revenues: 2)

      member3 = book_member_fixture(book)
      balance_config3 = member_balance_config_fixture(member3, revenues: 2)

      member4 = book_member_fixture(book)
      balance_config4 = member_balance_config_fixture(member4, revenues: 3)

      transfer =
        money_transfer_fixture(book,
          tenant_id: member1.id,
          balance_means: :weight_by_revenues,
          amount: Money.new!(:EUR, 9)
        )

      _peer = peer_fixture(transfer, member_id: member1.id, balance_config_id: balance_config1.id)
      _peer = peer_fixture(transfer, member_id: member2.id, balance_config_id: balance_config2.id)
      _peer = peer_fixture(transfer, member_id: member3.id, balance_config_id: balance_config3.id)
      _peer = peer_fixture(transfer, member_id: member4.id, balance_config_id: balance_config4.id)

      [member1, member2, member3, member4] =
        Balance.fill_members_balance([member1, member2, member3, member4])

      assert Money.equal?(member1.balance, Money.new!(:EUR, 7))
      assert Money.equal?(member2.balance, Money.new!(:EUR, -2))
      assert Money.equal?(member3.balance, Money.new!(:EUR, -2))
      assert Money.equal?(member4.balance, Money.new!(:EUR, -3))
    end

    test "weighting by incomes takes user-defined weight into account", %{book: book} do
      member1 = book_member_fixture(book)
      balance_config1 = member_balance_config_fixture(member1, revenues: 1)

      member2 = book_member_fixture(book)
      balance_config2 = member_balance_config_fixture(member2, revenues: 2)

      member3 = book_member_fixture(book)
      balance_config3 = member_balance_config_fixture(member3, revenues: 3)

      transfer =
        money_transfer_fixture(book,
          tenant_id: member1.id,
          balance_means: :weight_by_revenues,
          amount: Money.new!(:EUR, 100)
        )

      _peer =
        peer_fixture(transfer,
          member_id: member1.id,
          weight: Decimal.new(1),
          balance_config_id: balance_config1.id
        )

      _peer =
        peer_fixture(transfer,
          member_id: member2.id,
          weight: Decimal.new(2),
          balance_config_id: balance_config2.id
        )

      _peer =
        peer_fixture(transfer,
          member_id: member3.id,
          weight: Decimal.new(3),
          balance_config_id: balance_config3.id
        )

      [member1, member2, member3] = Balance.fill_members_balance([member1, member2, member3])
      assert Money.equal?(member1.balance, Money.new!(:EUR, "92.86"))
      assert Money.equal?(member2.balance, Money.new!(:EUR, "-28.57"))
      assert Money.equal?(member3.balance, Money.new!(:EUR, "-64.29"))
    end

    test "fails if a user config appropriate fields aren't set", %{book: book} do
      member1 = book_member_fixture(book, nickname: "member1")
      balance_config1 = member_balance_config_fixture(member1, revenues: nil)

      member2 = book_member_fixture(book)
      balance_config2 = member_balance_config_fixture(member2, revenues: 1)

      member3 = book_member_fixture(book)
      balance_config3 = member_balance_config_fixture(member3, revenues: 1)

      transfer1 =
        money_transfer_fixture(book,
          tenant_id: member1.id,
          balance_means: :weight_by_revenues,
          amount: Money.new!(:EUR, 30)
        )

      _peer =
        peer_fixture(transfer1, member_id: member1.id, balance_config_id: balance_config1.id)

      _peer =
        peer_fixture(transfer1, member_id: member2.id, balance_config_id: balance_config2.id)

      transfer2 =
        money_transfer_fixture(book,
          tenant_id: member1.id,
          balance_means: :weight_by_revenues,
          amount: Money.new!(:EUR, 40)
        )

      _peer =
        peer_fixture(transfer2, member_id: member2.id, balance_config_id: balance_config2.id)

      _peer =
        peer_fixture(transfer2, member_id: member3.id, balance_config_id: balance_config3.id)

      [member1, member2, member3] = Balance.fill_members_balance([member1, member2, member3])

      member1_id = member1.id
      expected_hash = "revenues_missing_#{member1_id}"

      assert member1.balance_errors == [
               %BalanceError{
                 kind: :revenues_missing,
                 uniq_hash: expected_hash,
                 extra: %{member_id: member1_id},
                 private: %{member_nickname: "member1"}
               }
             ]

      assert member2.balance_errors == [
               %BalanceError{
                 kind: :revenues_missing,
                 uniq_hash: expected_hash,
                 extra: %{member_id: member1_id},
                 private: %{member_nickname: "member1"}
               }
             ]

      assert Money.equal?(member3.balance, Money.new!(:EUR, -20))
    end

    test "does not crash if the book is correctly balanced", %{book: book} do
      member1 = book_member_fixture(book)
      member2 = book_member_fixture(book)
      member3 = book_member_fixture(book)

      transfer1 =
        money_transfer_fixture(book,
          amount: Money.new!(:EUR, 300),
          tenant_id: member1.id
        )

      _peer = peer_fixture(transfer1, member_id: member1.id)
      _peer = peer_fixture(transfer1, member_id: member2.id)
      _peer = peer_fixture(transfer1, member_id: member3.id)

      reimbursement1 =
        money_transfer_fixture(book,
          amount: Money.new!(:EUR, 100),
          type: :reimbursement,
          tenant_id: member1.id
        )

      _reimbursement_peer = peer_fixture(reimbursement1, member_id: member2.id)

      reimbursement2 =
        money_transfer_fixture(book,
          amount: Money.new!(:EUR, 100),
          type: :reimbursement,
          tenant_id: member1.id
        )

      _reimbursement_peer = peer_fixture(reimbursement2, member_id: member3.id)

      [member1, member2, member3] = Balance.fill_members_balance([member1, member2, member3])
      assert Money.equal?(member1.balance, Money.new!(:EUR, 0))
      assert Money.equal?(member2.balance, Money.new!(:EUR, 0))
      assert Money.equal?(member3.balance, Money.new!(:EUR, 0))
    end
  end

  describe "transactions/1" do
    setup do
      %{book: book_fixture()}
    end

    test "creates transactions to balance members money #1", %{book: book} do
      member1 = book_member_fixture(book, balance: Money.new!(:EUR, 10))
      member2 = book_member_fixture(book, balance: Money.new!(:EUR, -10))
      member3 = book_member_fixture(book, balance: Money.new!(:EUR, 0))

      assert {:ok, transactions} = Balance.transactions([member1, member2, member3])

      assert transactions_equal?(transactions, [
               %{
                 id: "#{member2.id}-#{member1.id}",
                 from: member2,
                 to: member1,
                 amount: Money.new!(:EUR, 10)
               }
             ])
    end

    test "creates transactions to balance members money #2", %{book: book} do
      member1 = book_member_fixture(book, balance: Money.new!(:EUR, 120))
      member2 = book_member_fixture(book, balance: Money.new!(:EUR, 33))
      member3 = book_member_fixture(book, balance: Money.new!(:EUR, -12))
      member4 = book_member_fixture(book, balance: Money.new!(:EUR, -121))
      member5 = book_member_fixture(book, balance: Money.new!(:EUR, -20))

      assert {:ok, transactions} =
               Balance.transactions([member1, member2, member3, member4, member5])

      assert transactions_equal?(transactions, [
               %{
                 id: "#{member5.id}-#{member2.id}",
                 from: member5,
                 to: member2,
                 amount: Money.new!(:EUR, 20)
               },
               %{
                 id: "#{member4.id}-#{member2.id}",
                 from: member4,
                 to: member2,
                 amount: Money.new!(:EUR, 13)
               },
               %{
                 id: "#{member4.id}-#{member1.id}",
                 from: member4,
                 to: member1,
                 amount: Money.new!(:EUR, 108)
               },
               %{
                 id: "#{member3.id}-#{member1.id}",
                 from: member3,
                 to: member1,
                 amount: Money.new!(:EUR, 12)
               }
             ])
    end

    test "retuns an empty array if given no members", _context do
      assert Balance.transactions([]) == {:ok, []}
    end

    test "returns :error when the balance of a member is corrupted", %{book: book} do
      member1 = book_member_fixture(book, balance: Money.new!(:EUR, 10))

      member2 =
        book_member_fixture(book,
          balance: Money.new!(:EUR, 10),
          balance_errors: ["could not compute balance"]
        )

      assert Balance.transactions([member1, member2]) == {:error, ["could not compute balance"]}
    end

    defp transactions_equal?(transactions1, transactions2) do
      Enum.map(transactions1, &serialize_transaction/1) ==
        Enum.map(transactions2, &serialize_transaction/1)
    end

    defp serialize_transaction(transaction) do
      %{transaction | from: transaction.from.id, to: transaction.to.id}
    end
  end
end
