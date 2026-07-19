defmodule App.Repo.Migrations.MakeMoneyTransfersCreatorIDNotNullable do
  use Ecto.Migration

  def change do
    execute "ALTER TABLE money_transfers ALTER COLUMN creator_id SET NOT NULL",
            "ALTER TABLE money_transfers ALTER COLUMN creator_id DROP NOT NULL"
  end
end
