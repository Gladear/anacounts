defmodule App.Repo.Migrations.CreateInvitationTokenIndexes do
  use Ecto.Migration

  @disable_ddl_transaction true
  @disable_migration_lock true

  def change do
    create index(:invitation_tokens, [:book_member_id], concurrently: true)
    create unique_index(:invitation_tokens, [:token], concurrently: true)
  end
end
