defmodule App.Repo.Migrations.CreateRecipientUniqueIndex do
  use Ecto.Migration

  @disable_ddl_transaction true
  @disable_migration_lock true

  def change do
    create unique_index(:notification_recipients, [:notification_id, :user_id],
             concurrently: true
           )
  end
end
