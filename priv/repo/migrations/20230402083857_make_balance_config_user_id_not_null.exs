defmodule App.Repo.Migrations.MakeBalanceConfigUserIdNotNull do
  use Ecto.Migration

  def change do
    execute "ALTER TABLE balance_configs ALTER COLUMN user_id SET NOT NULL",
            "ALTER TABLE balance_configs ALTER COLUMN user_id DROP NOT NULL"
  end
end
