defmodule App.Repo.Migrations.DropInvitationTokens do
  use Ecto.Migration

  def up do
    drop table(:invitation_tokens)
  end

  def down do
    create table(:invitation_tokens) do
      add :token, :binary, null: false
      add :sent_to, :string, null: false
      add :book_member_id, references(:book_members, on_delete: :delete_all), null: false

      timestamps(updated_at: false)
    end

    create index(:invitation_tokens, [:book_member_id])
    create unique_index(:invitation_tokens, [:token])
  end
end
