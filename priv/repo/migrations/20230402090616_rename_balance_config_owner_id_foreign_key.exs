defmodule App.Repo.Migrations.RenameBalanceConfigOwnerIdForeignKey do
  use Ecto.Migration

  def change do
    rename_constraint(
      "balance_configs",
      "balance_configs_user_id_fkey",
      "balance_configs_owner_id_fkey"
    )
  end

  defp rename_constraint(table, from, to) do
    execute "ALTER TABLE #{table} RENAME CONSTRAINT #{from} TO #{to}",
            "ALTER TABLE #{table} RENAME CONSTRAINT #{to} TO #{from}"
  end
end
