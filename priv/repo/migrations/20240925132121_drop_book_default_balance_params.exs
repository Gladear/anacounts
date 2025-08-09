defmodule App.Repo.Migrations.DropBookDefaultBalanceParams do
  use Ecto.Migration

  def change do
    alter table(:books) do
      remove :default_balance_params, :balance_transfer_params, null: false
    end
  end
end
