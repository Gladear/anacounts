defmodule App.Repo.Migrations.RenameUserBalanceConfigs do
  use Ecto.Migration

  def change do
    rename table(:user_balance_config), to: table(:user_balance_configs)

    rename_index("user_balance_config_pkey", "user_balance_configs_pkey")
    rename_index("user_balance_config_user_id_index", "user_balance_configs_user_id_index")

    rename_constraint(
      "user_balance_configs",
      "user_balance_config_user_id_fkey",
      "user_balance_configs_user_id_fkey"
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
