defmodule App.Repo.Migrations.DropNotifications do
  use Ecto.Migration

  def change do
    drop table(:notification_recipients)
    drop table(:notifications)
    execute "DROP TYPE notifications_type"
  end
end
