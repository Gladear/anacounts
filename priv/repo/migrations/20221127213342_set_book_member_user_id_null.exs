defmodule App.Repo.Migrations.SetBookMemberUserIdNull do
  use Ecto.Migration

  def change do
    execute "ALTER TABLE book_members ALTER COLUMN user_id DROP NOT NULL", ""
  end
end
