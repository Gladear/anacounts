defmodule App.Repo.Migrations.DeleteSoftDeletedBooks do
  use Ecto.Migration

  def up do
    execute "DELETE FROM books WHERE deleted_at IS NOT NULL", ""
  end

  def down, do: :ok
end
