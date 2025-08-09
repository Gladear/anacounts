defmodule App.Repo.Migrations.RemoveBalanceConfigsOwnerIdUniqueConstraint do
  use Ecto.Migration

  @disable_ddl_transaction true
  @disable_migration_lock true

  def change do
    drop unique_index(:balance_configs, [:owner_id],
           name: "balance_configs_user_id_index",
           concurrently: true
         )

    create index(:balance_configs, [:owner_id], concurrently: true)
  end
end
