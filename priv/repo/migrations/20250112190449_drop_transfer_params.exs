defmodule App.Repo.Migrations.DropTransferParams do
  use Ecto.Migration

  def change do
    # Validate NOT NULL constraint on balance_means
    execute "ALTER TABLE money_transfers VALIDATE CONSTRAINT balance_means_not_null", ""

    execute "ALTER TABLE money_transfers ALTER COLUMN balance_means SET NOT NULL",
            "ALTER TABLE money_transfers ALTER COLUMN balance_means DROP NOT NULL"

    drop constraint("money_transfers", :balance_means_not_null)

    # Drop former column `:balance_params
    alter table("money_transfers") do
      remove :balance_params, :balance_transfer_params
    end

    execute "DROP TYPE balance_transfer_params",
            "CREATE TYPE balance_transfer_params AS (means_code balance_means_code, params JSONB)"

    execute "DROP TYPE balance_means_code",
            "CREATE TYPE balance_means_code AS ENUM ('divide_equally', 'weight_by_income')"
  end
end
