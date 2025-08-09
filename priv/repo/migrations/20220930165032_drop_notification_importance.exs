defmodule App.Repo.Migrations.DropNotificationImportance do
  use Ecto.Migration

  def change do
    alter table(:notifications) do
      remove :importance, :notifications_importance, null: false
    end

    execute "DROP TYPE notifications_importance",
            "CREATE TYPE notifications_importance AS ENUM ('low', 'medium', 'high')"
  end
end
