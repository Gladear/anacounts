defmodule App.Repo.Migrations.BackfillTransfersCreatorID do
  use Ecto.Migration

  def up do
    # Since the creator information is not available, consider the tenant as the creator
    execute "UPDATE money_transfers SET creator_id = tenant_id WHERE creator_id IS NULL",
            ""
  end

  def down, do: :ok
end
