defmodule App.Repo.Migrations.AddNotificationType do
  use Ecto.Migration

  def change do
    execute "CREATE TYPE notifications_type AS ENUM ('admin_announcement')",
            "DROP TYPE notifications_type"

    alter table(:notifications) do
      add :type, :notifications_type, default: "admin_announcement", null: false
    end

    execute "ALTER TABLE notifications ALTER COLUMN type DROP DEFAULT", ""
  end
end
