defmodule App.Repo.Migrations.RenameHolderToTenant do
  use Ecto.Migration

  def change do
    rename(table(:transfers_money_transfers), :holder_id, to: :tenant_id)

    execute(
      """
      ALTER TABLE transfers_money_transfers
      RENAME
        CONSTRAINT transfers_money_transfers_holder_id_fkey
        TO transfers_money_transfers_tenant_id_fkey
      """,
      """
      ALTER TABLE transfers_money_transfers
      RENAME
        CONSTRAINT transfers_money_transfers_tenant_id_fkey
        TO transfers_money_transfers_holder_id_fkey
      """
    )

    execute(
      """
      ALTER INDEX transfers_money_transfers_holder_id_index
      RENAME TO transfers_money_transfers_tenant_id_index
      """,
      """
      ALTER INDEX transfers_money_transfers_tenant_id_index
      RENAME TO transfers_money_transfers_holder_id_index
      """
    )
  end
end
