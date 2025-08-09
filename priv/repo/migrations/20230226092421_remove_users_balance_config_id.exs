defmodule App.Repo.Migrations.RemoveUsersBalanceConfigId do
  use Ecto.Migration

  def change do
    alter table("users") do
      remove :balance_config_id, references("balance_configs", on_delete: :delete_all)
    end
  end
end
