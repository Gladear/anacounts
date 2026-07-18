defmodule App.Repo.Migrations.AddBookMemberArchivedAt do
  use Ecto.Migration

  def change do
    alter table(:book_members) do
      add :archived_at, :naive_datetime
    end

    create constraint(:book_members, :archived_at_null_if_user_id_null,
             check: "archived_at IS NULL OR user_id IS NULL"
           )
  end
end
