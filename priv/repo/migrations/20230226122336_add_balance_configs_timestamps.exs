defmodule App.Repo.Migrations.AddBalanceConfigsTimestamps do
  use Ecto.Migration

  def change do
    alter table("balance_configs") do
      timestamps(default: fragment("now()"))
    end

    execute """
            ALTER TABLE balance_configs
              ALTER COLUMN inserted_at DROP DEFAULT,
              ALTER COLUMN updated_at DROP DEFAULT
            """,
            """
            ALTER TABLE balance_configs
              ALTER COLUMN inserted_at SET DEFAULT now(),
              ALTER COLUMN updated_at SET DEFAULT now()
            """
  end
end
