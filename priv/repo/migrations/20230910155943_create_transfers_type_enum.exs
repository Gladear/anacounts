defmodule App.Repo.Migrations.CreateTransfersTypeEnum do
  use Ecto.Migration

  def change do
    execute "CREATE TYPE money_transfers_type AS ENUM ('payment', 'income', 'reimbursement')",
            "DROP TYPE money_transfers_type"

    execute """
            ALTER TABLE money_transfers
            ALTER COLUMN type TYPE money_transfers_type USING type::money_transfers_type
            """,
            """
            ALTER TABLE money_transfers
            ALTER COLUMN type TYPE varchar USING type::varchar
            """
  end
end
