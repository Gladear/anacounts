defmodule App.Repo.Migrations.RenameBooks do
  use Ecto.Migration

  def change do
    rename table("accounts_books"), to: table("books")

    execute(
      "ALTER INDEX accounts_books_pkey RENAME TO books_pkey",
      "ALTER INDEX books_pkey RENAME TO accounts_books_pkey"
    )
  end
end
