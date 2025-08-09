defmodule App.Repo.Migrations.CreateBalanceUserParamsIndexes do
  use Ecto.Migration
  @disable_ddl_transaction true
  @disable_migration_lock true

  def change do
    create(index(:balance_user_params, :user_id, concurrently: true))
    create(index(:balance_user_params, :means_code, concurrently: true))
    create(unique_index(:balance_user_params, [:user_id, :means_code], concurrently: true))
  end
end
