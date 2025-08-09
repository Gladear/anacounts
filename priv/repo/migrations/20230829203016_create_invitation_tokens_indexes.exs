defmodule App.Repo.Migrations.CreateInvitationTokensIndexes do
  use Ecto.Migration

  @disable_ddl_transaction true
  @disable_migration_lock true

  def change do
    create index(:invitation_tokens, [:token], unique: true, concurrently: true)
    create index(:invitation_tokens, [:book_id], unique: true, concurrently: true)
  end
end
