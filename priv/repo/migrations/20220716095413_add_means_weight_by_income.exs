defmodule App.Repo.Migrations.AddMeansWeightByIncome do
  use Ecto.Migration

  def change do
    execute("ALTER TYPE balance_means_code ADD VALUE 'weight_by_income'", "")
  end
end
