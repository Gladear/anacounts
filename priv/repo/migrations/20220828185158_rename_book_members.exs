defmodule App.Repo.Migrations.RenameBookMembers do
  use Ecto.Migration

  def change do
    rename table("accounts_book_members"), to: table("book_members")

    execute(
      "ALTER INDEX accounts_book_members_pkey RENAME TO book_members_pkey",
      "ALTER INDEX book_members_pkey RENAME TO accounts_book_members_pkey"
    )

    execute(
      "ALTER INDEX accounts_book_members_book_id_user_id_index RENAME TO book_members_book_id_user_id_index",
      "ALTER INDEX book_members_book_id_user_id_index RENAME TO accounts_book_members_book_id_user_id_index"
    )

    execute(
      "ALTER INDEX accounts_book_members_book_id_index RENAME TO book_members_book_id_index",
      "ALTER INDEX book_members_book_id_index RENAME TO accounts_book_members_book_id_index"
    )

    execute(
      "ALTER INDEX accounts_book_members_user_id_index RENAME TO book_members_user_id_index",
      "ALTER INDEX book_members_user_id_index RENAME TO accounts_book_members_user_id_index"
    )

    execute(
      "ALTER TABLE book_members RENAME CONSTRAINT accounts_book_members_book_id_fkey TO book_members_book_id_fkey",
      "ALTER TABLE book_members RENAME CONSTRAINT book_members_book_id_fkey TO accounts_book_members_book_id_fkey"
    )

    execute(
      "ALTER TABLE book_members RENAME CONSTRAINT accounts_book_members_user_id_fkey TO book_members_user_id_fkey",
      "ALTER TABLE book_members RENAME CONSTRAINT book_members_user_id_fkey TO accounts_book_members_user_id_fkey"
    )
  end
end
