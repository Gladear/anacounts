defmodule App.Repo.Migrations.CreateInvitationToken do
  use Ecto.Migration

  def change do
    create table(:invitation_tokens) do
      add :token, :binary, null: false
      add :sent_to, :string, null: false
      add :book_member_id, references(:book_members, on_delete: :delete_all), null: false

      timestamps(updated_at: false)
    end
  end
end
