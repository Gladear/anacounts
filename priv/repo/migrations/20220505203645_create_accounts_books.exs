defmodule App.Repo.Migrations.CreateAccountsBooksTables do
  use Ecto.Migration

  def change do
    create table(:accounts_books) do
      add(:name, :string, null: false)
      add(:deleted_at, :naive_datetime)

      timestamps()
    end

    create table(:accounts_book_members) do
      add(:book_id, references(:accounts_books, on_delete: :delete_all, on_update: :update_all),
        null: false
      )

      add(:user_id, references(:users, on_delete: :delete_all, on_update: :update_all),
        null: false
      )

      add(:role, :string, null: false)
      add(:deleted_at, :naive_datetime)

      timestamps()
    end
  end
end
