defmodule App.Repo.Migrations.RenameBalanceConfig do
  use Ecto.Migration

  def change do
    rename table("user_balance_configs"), to: table("balance_configs")
  end
end
