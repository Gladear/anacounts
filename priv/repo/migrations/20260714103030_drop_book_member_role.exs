defmodule App.Repo.Migrations.DropBookMemberRole do
  use Ecto.Migration

  def change do
    alter table(:book_members) do
      remove :role, :string, null: false
    end
  end
end
