defmodule App.Repo.Migrations.DropBooksDeletedAt do
  use Ecto.Migration

  def change do
    alter table(:books) do
      remove :deleted_at, :naive_datetime
    end
  end
end
