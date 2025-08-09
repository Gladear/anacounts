defmodule App.Repo.Migrations.RenameBalanceMeansWeightByRevenues do
  use Ecto.Migration

  def change do
    execute "ALTER TYPE balance_means RENAME VALUE 'weight_by_income' TO 'weight_by_revenues'",
            "ALTER TYPE balance_means RENAME VALUE 'weight_by_revenues' TO 'weight_by_income'"
  end
end
