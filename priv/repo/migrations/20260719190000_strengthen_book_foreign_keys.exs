defmodule App.Repo.Migrations.StrengthenBookForeignKeys do
  use Ecto.Migration

  def change do
    execute """
            ALTER TABLE book_members
            DROP CONSTRAINT book_members_book_id_fkey,
            ADD FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE CASCADE
            """,
            """
            ALTER TABLE book_members
            DROP CONSTRAINT book_members_book_id_fkey,
            ADD FOREIGN KEY (book_id) REFERENCES books(id) ON UPDATE CASCADE ON DELETE CASCADE
            """

    execute """
            ALTER TABLE money_transfers
            DROP CONSTRAINT money_transfers_creator_id_fkey,
            ADD FOREIGN KEY (creator_id) REFERENCES book_members(id) ON DELETE RESTRICT
            """,
            """
            ALTER TABLE money_transfers
            DROP CONSTRAINT money_transfers_creator_id_fkey,
            ADD FOREIGN KEY (creator_id) REFERENCES book_members(id) ON DELETE SET NULL
            """

    execute """
            ALTER TABLE transfers_peers
            DROP CONSTRAINT transfers_peers_member_id_fkey,
            ADD FOREIGN KEY (member_id) REFERENCES book_members(id) ON DELETE RESTRICT
            """,
            """
            ALTER TABLE transfers_peers
            DROP CONSTRAINT transfers_peers_member_id_fkey,
            ADD FOREIGN KEY (member_id) REFERENCES book_members(id) ON DELETE CASCADE
            """
  end
end
