defmodule App.Repo.Migrations.CreateTransfersIndexes do
  use Ecto.Migration
  @disable_ddl_transaction true
  @disable_migration_lock true

  def change do
    create(index(:transfers_money_transfers, :book_id, concurrently: true))
    create(index(:transfers_money_transfers, :holder_id, concurrently: true))

    create(index(:transfers_peers, :transfer_id, concurrently: true))
    create(index(:transfers_peers, :member_id, concurrently: true))
    create(unique_index(:transfers_peers, [:transfer_id, :member_id], concurrently: true))
  end
end
