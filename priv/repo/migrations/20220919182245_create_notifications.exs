defmodule App.Repo.Migrations.CreateNotifications do
  use Ecto.Migration

  def change do
    execute "CREATE TYPE notifications_importance AS ENUM ('low', 'medium', 'high')",
            "DROP TYPE notifications_importance"

    create table(:notifications) do
      add :content, :text, null: false
      add :importance, :notifications_importance, null: false

      timestamps()
    end
  end
end
