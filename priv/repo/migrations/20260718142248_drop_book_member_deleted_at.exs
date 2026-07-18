defmodule App.Repo.Migrations.DropBookMemberDeletedAt do
  use Ecto.Migration

  def change do
    alter table(:book_members) do
      remove :deleted_at, :naive_datetime
    end
  end
end
