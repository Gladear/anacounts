defmodule App.Repo.Migrations.DropUsersBalanceConfigId do
  use Ecto.Migration

  def change do
    alter table(:users) do
      remove :balance_config_id, references(:balance_configs, on_delete: :restrict)
    end
  end
end
