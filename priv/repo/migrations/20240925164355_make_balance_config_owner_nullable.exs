defmodule App.Repo.Migrations.MakeBalanceConfigOwnerNullable do
  use Ecto.Migration

  def change do
    execute "ALTER TABLE balance_configs ALTER COLUMN owner_id DROP NOT NULL",
            "ALTER TABLE balance_configs ALTER COLUMN owner_id SET NOT NULL"
  end
end
