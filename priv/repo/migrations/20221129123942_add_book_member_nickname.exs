defmodule App.Repo.Migrations.AddBookMemberNickname do
  use Ecto.Migration

  def up do
    alter table(:book_members) do
      add :nickname, :string, default: "Undefined", null: false
    end

    alter table(:book_members) do
      modify :nickname, :string, null: false
    end
  end

  def down do
    alter table(:book_members) do
      remove :nickname
    end
  end
end
