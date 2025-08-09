defmodule App.Repo.Migrations.CreateAccountsIndexes do
  use Ecto.Migration
  @disable_ddl_transaction true
  @disable_migration_lock true

  def change do
    create(index(:accounts_book_members, :book_id, concurrently: true))
    create(index(:accounts_book_members, :user_id, concurrently: true))
    create(unique_index(:accounts_book_members, [:book_id, :user_id], concurrently: true))
  end
end
