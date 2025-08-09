defmodule App.Repo.Migrations.AddBooksClosedAt do
  use Ecto.Migration

  def change do
    alter table(:books) do
      add :closed_at, :naive_datetime
    end
  end
end
