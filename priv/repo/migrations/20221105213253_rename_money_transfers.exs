defmodule App.Repo.Migrations.RenameMoneyTransfers do
  use Ecto.Migration

  def change do
    rename table(:transfers_money_transfers), to: table(:money_transfers)

    rename_index("transfers_money_transfers_pkey", "money_transfers_pkey")
    rename_index("transfers_money_transfers_book_id_index", "money_transfers_book_id_index")
    rename_index("transfers_money_transfers_tenant_id_index", "money_transfers_tenant_id_index")

    rename_constraint(
      "money_transfers",
      "transfers_money_transfers_book_id_fkey",
      "money_transfers_book_id_fkey"
    )

    rename_constraint(
      "money_transfers",
      "transfers_money_transfers_tenant_id_fkey",
      "money_transfers_tenant_id_fkey"
    )
  end

  defp rename_index(from, to) do
    execute "ALTER INDEX #{from} RENAME TO #{to}",
            "ALTER INDEX #{to} RENAME TO #{from}"
  end

  defp rename_constraint(table, from, to) do
    execute "ALTER TABLE #{table} RENAME CONSTRAINT #{from} TO #{to}",
            "ALTER TABLE #{table} RENAME CONSTRAINT #{to} TO #{from}"
  end
end
