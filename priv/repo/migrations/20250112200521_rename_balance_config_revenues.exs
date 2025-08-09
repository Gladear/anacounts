defmodule App.Repo.Migrations.RenameBalanceConfigRevenues do
  use Ecto.Migration

  def change do
    rename table("balance_configs"), :annual_income, to: :revenues
  end
end
