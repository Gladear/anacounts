defmodule App.Repo.Migrations.AddBalanceConfigBookMemberId do
  use Ecto.Migration

  def change do
    alter table("balance_configs") do
      add :book_member_id, references("book_members", on_delete: :delete_all)
    end

    create unique_index(:balance_configs, [:book_member_id])

    execute "ALTER TABLE balance_configs ALTER COLUMN user_id DROP NOT NULL",
            "ALTER TABLE balance_configs ALTER COLUMN user_id SET NOT NULL"

    create constraint(:balance_configs, :either_user_or_book_member_id,
             check: "num_nulls(user_id, book_member_id) = 1"
           )
  end
end
