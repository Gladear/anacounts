defmodule App.Repo.Migrations.AddBalanceConfigCreatedFor do
  use Ecto.Migration

  def change do
    execute "CREATE TYPE balance_config_created_for AS ENUM ('user', 'book_member')",
            "DROP TYPE balance_config_created_for"

    alter table("balance_configs") do
      add :created_for, :balance_config_created_for, default: "user", null: false
    end

    execute "ALTER TABLE balance_configs ALTER COLUMN created_for DROP DEFAULT", ""
  end
end
