defmodule App.Repo.Migrations.AddUsersBalanceConfigId do
  use Ecto.Migration

  def change do
    alter table("users") do
      add :balance_config_id, references("balance_configs", on_delete: :delete_all)
    end
  end
end
