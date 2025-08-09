defmodule App.Repo.Migrations.AddTransferParamsField do
  use Ecto.Migration

  def change do
    # Add to book
    alter table(:accounts_books) do
      add(:default_balance_params, :balance_transfer_params,
        null: false,
        # add a default so the column is filled with values when created, but remove it afterwards
        default: fragment("('divide_equally', '{}'::JSONB)")
      )
    end

    execute("ALTER TABLE accounts_books ALTER COLUMN default_balance_params DROP DEFAULT", "")

    # Add to money transfers
    alter table(:transfers_money_transfers) do
      add(:balance_params, :balance_transfer_params)
    end
  end
end
