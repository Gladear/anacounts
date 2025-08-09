defmodule App.Repo.Migrations.ChangeMoneyTrangerDateTimeToDate do
  use Ecto.Migration

  def change do
    alter table(:transfers_money_transfers) do
      modify(:date, :date, default: fragment("now()"), null: false, from: :utc_datetime)
    end
  end
end
