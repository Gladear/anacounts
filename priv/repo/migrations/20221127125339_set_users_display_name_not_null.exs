defmodule App.Repo.Migrations.SetUsersDisplayNameNotNull do
  use Ecto.Migration

  def change do
    execute "ALTER TABLE users VALIDATE CONSTRAINT display_name_is_not_null", ""

    alter table(:users) do
      modify :display_name, :string, null: false
    end

    drop constraint("users", :display_name_is_not_null)
  end
end
