defmodule App.Repo.Migrations.AddMoneyTransfersBalanceMeans do
  use Ecto.Migration

  def change do
    execute "CREATE TYPE balance_means AS ENUM ('divide_equally', 'weight_by_income')"

    alter table(:money_transfers) do
      add :balance_means, :balance_means
    end

    create constraint(:money_transfers, :balance_means_not_null,
             check: "balance_means IS NOT NULL",
             validate: false
           )
  end
end
