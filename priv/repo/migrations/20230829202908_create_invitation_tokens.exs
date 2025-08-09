defmodule App.Repo.Migrations.CreateInvitationTokens do
  use Ecto.Migration

  def change do
    create table(:invitation_tokens) do
      add :token, :binary, null: false
      add :book_id, references(:books, on_delete: :delete_all), null: false

      timestamps(updated_at: false)
    end
  end
end
