defmodule App.Repo.Migrations.SetNotificationTitleLengthTo80 do
  use Ecto.Migration

  def change do
    alter table(:notifications) do
      modify :title, :string, size: 80, from: :string
    end
  end
end
