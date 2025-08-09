defmodule App.Repo.Migrations.AddBalanceConfigStartDateOfValidity do
  use Ecto.Migration

  def change do
    alter table("balance_configs") do
      add :start_date_of_validity, :utc_datetime
    end

    # This is bad, don't do this at home
    execute "UPDATE balance_configs SET start_date_of_validity = inserted_at", ""

    execute "ALTER TABLE balance_configs ALTER COLUMN start_date_of_validity SET NOT NULL", ""
  end
end
