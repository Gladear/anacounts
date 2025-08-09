defmodule App.Repo.Migrations.DropBalanceConfigCreatedFor do
  use Ecto.Migration

  def change do
    alter table("balance_configs") do
      remove :created_for, :balance_config_created_for, default: "user", null: false
    end

    execute "DROP TYPE balance_config_created_for",
            "CREATE TYPE balance_config_created_for AS ENUM ('user', 'book_member')"
  end
end
