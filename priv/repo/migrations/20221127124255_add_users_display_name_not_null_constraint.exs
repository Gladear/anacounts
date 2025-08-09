defmodule App.Repo.Migrations.AddUsersDisplayNameNotNullConstraint do
  use Ecto.Migration

  def change do
    create constraint(:users, :display_name_is_not_null,
             check: "display_name IS NOT NULL",
             validate: false
           )
  end
end
