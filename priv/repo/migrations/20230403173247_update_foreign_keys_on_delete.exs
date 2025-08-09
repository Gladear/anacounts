defmodule App.Repo.Migrations.UpdateForeignKeysOnDelete do
  use Ecto.Migration

  def change do
    execute """
            ALTER TABLE transfers_peers
            DROP CONSTRAINT transfers_peers_member_id_fkey,
            ADD FOREIGN KEY  (member_id) REFERENCES book_members(id) ON DELETE CASCADE
            """,
            """
            ALTER TABLE transfers_peers
            DROP CONSTRAINT transfers_peers_member_id_fkey,
            ADD FOREIGN KEY (member_id) REFERENCES book_members(id) ON DELETE RESTRICT
            """

    execute """
            ALTER TABLE book_members
            DROP CONSTRAINT book_members_user_id_fkey,
            ADD FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
            """,
            """
            ALTER TABLE book_members
            DROP CONSTRAINT book_members_user_id_fkey,
            ADD FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
            """

    execute """
            ALTER TABLE balance_configs
            DROP CONSTRAINT balance_configs_owner_id_fkey,
            ADD FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE SET NULL
            """,
            """
            ALTER TABLE balance_configs
            DROP CONSTRAINT balance_configs_owner_id_fkey,
            ADD FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE CASCADE
            """
  end
end
