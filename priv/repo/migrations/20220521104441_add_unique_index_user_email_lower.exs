defmodule App.Repo.Migrations.AddUniqueIndexUserEmailLower do
  use Ecto.Migration

  def change do
    create(unique_index(:users, ["lower(email)"]))
  end
end
