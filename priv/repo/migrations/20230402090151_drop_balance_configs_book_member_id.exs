defmodule App.Repo.Migrations.DropBalanceConfigsBookMemberId do
  use Ecto.Migration

  def change do
    alter table(:balance_configs) do
      remove :book_member_id, references(:book_members, on_delete: :delete_all)
    end
  end
end
