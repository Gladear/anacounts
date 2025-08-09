defmodule App.Repo.Migrations.RenameBalanceConfigsOwnerId do
  use Ecto.Migration

  def change do
    rename table("balance_configs"), :user_id, to: :owner_id
  end
end
