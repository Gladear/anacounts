# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     App.Repo.insert!(%App.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

## Accounts

alias App.Accounts

{:ok, user} =
  Accounts.register_user(%{
    email: "anacounts@example.com",
    password: "azertyuiop12345!"
  })

{:ok, user_2} =
  Accounts.register_user(%{
    email: "member_2@example.com",
    password: "azertyuiop12345!"
  })

## Books

alias App.Books
alias App.Books.Members

{:ok, book} = Books.create_book(%{name: "Sample Book", nickname: "Anacounts"}, user)

{:ok, member_2} = Members.create_book_member_for_user(book, user_2, %{nickname: "Member 2"})
{:ok, member_3} = Members.create_book_member(book, %{nickname: "Member 3"})
{:ok, member_4} = Members.create_book_member(book, %{nickname: "Member 4"})

## Money transfers

alias App.Transfers

{:ok, _payment} =
  Transfers.create_money_transfer(book, member_2, :payment, %{
    tenant_id: member_2.id,
    label: "Groceries",
    amount: Decimal.new("42.50"),
    date: ~D[2026-07-01],
    balance_means: :divide_equally,
    peers: [
      %{member_id: member_2.id},
      %{member_id: member_3.id},
      %{member_id: member_4.id}
    ]
  })

{:ok, _income} =
  Transfers.create_money_transfer(book, member_2, :income, %{
    tenant_id: member_2.id,
    label: "Refund from supplier",
    amount: Decimal.new("15.00"),
    date: ~D[2026-07-03],
    balance_means: :divide_equally,
    peers: [
      %{member_id: member_2.id},
      %{member_id: member_3.id}
    ]
  })

{:ok, _reimbursement} =
  Transfers.create_reimbursement(book, member_3, %{
    label: "Reimbursement from Member 2 to Anacounts",
    amount: Decimal.new("20.00"),
    date: ~D[2026-07-05],
    tenant_id: member_3.id,
    peers: [%{member_id: member_2.id}]
  })
