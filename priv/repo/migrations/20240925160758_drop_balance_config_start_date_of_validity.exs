defmodule App.Repo.Migrations.DropBalanceConfigStartDateOfValidity do
  use Ecto.Migration

  def change do
    alter table("balance_configs") do
      remove :start_date_of_validity, :utc_datetime,
        default: "2020-01-01T00:00:00Z",
        null: false
    end
  end
end
