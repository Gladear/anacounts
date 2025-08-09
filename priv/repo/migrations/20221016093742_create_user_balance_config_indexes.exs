defmodule App.Repo.Migrations.CreateUserBalanceConfigIndexes do
  use Ecto.Migration

  @disable_ddl_transaction true
  @disable_migration_lock true

  def change do
    create unique_index(:user_balance_config, :user_id, concurrently: true)
  end
end
