defmodule App.Repo.Migrations.CreateNotificationRecipients do
  use Ecto.Migration

  def change do
    create table(:notification_recipients) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :notification_id, references(:notifications, on_delete: :delete_all), null: false
      add :read_at, :naive_datetime

      timestamps()
    end
  end
end
