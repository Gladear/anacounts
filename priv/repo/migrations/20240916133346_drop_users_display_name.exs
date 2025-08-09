defmodule App.Repo.Migrations.DropUsersDisplayName do
  use Ecto.Migration

  def change do
    alter table(:users) do
      remove :display_name, :string, null: false
    end
  end
end
