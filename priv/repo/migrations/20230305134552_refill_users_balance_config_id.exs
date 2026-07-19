defmodule App.Repo.Migrations.RefillUsersBalanceConfigId do
  use Ecto.Migration
  import Ecto.Query

  @disable_ddl_transaction true
  @disable_migration_lock true

  def up do
    repo().update_all(update_query(), [])
  end

  defp update_query do
    from u in "users",
      join: c in "balance_configs",
      on: c.user_id == u.id,
      update: [set: [balance_config_id: c.id]]
  end

  def down, do: :ok
end
