defmodule App.Repo.Migrations.RemoveConfirmedAtFromUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      remove :confirmed_at, :naive_datetime
    end
  end
end
