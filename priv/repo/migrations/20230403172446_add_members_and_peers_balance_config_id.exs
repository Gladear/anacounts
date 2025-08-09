defmodule App.Repo.Migrations.AddMembersAndPeersBalanceConfigId do
  use Ecto.Migration

  def change do
    alter table("book_members") do
      add :balance_config_id, references(:balance_configs, on_delete: :restrict)
    end

    alter table("transfers_peers") do
      add :balance_config_id, references(:balance_configs, on_delete: :restrict)
    end
  end
end
