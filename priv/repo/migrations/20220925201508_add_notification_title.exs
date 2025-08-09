defmodule App.Repo.Migrations.AddNotificationTitle do
  use Ecto.Migration

  def change do
    alter table(:notifications) do
      add :title, :string, default: "", null: false
    end

    execute "ALTER TABLE notifications ALTER COLUMN title DROP DEFAULT", ""
  end
end
