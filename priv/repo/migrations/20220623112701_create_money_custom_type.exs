defmodule App.Repo.Migrations.CreateMoneyCustomType do
  use Ecto.Migration

  def change do
    execute(
      "CREATE TYPE public.money_with_currency AS (amount integer, currency char(3))",
      "DROP TYPE public.money_with_currency"
    )
  end
end
