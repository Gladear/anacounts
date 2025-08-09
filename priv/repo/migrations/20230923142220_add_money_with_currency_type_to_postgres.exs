defmodule App.Repo.Migrations.AddMoneyWithCurrencyTypeToPostgres do
  use Ecto.Migration

  def up do
    execute "ALTER TYPE money_with_currency RENAME TO old_money_with_currency;"
    execute "CREATE TYPE public.money_with_currency AS (currency_code varchar, amount numeric);"

    execute """
    ALTER TABLE money_transfers
      ALTER COLUMN amount
      TYPE public.money_with_currency USING (('EUR'::varchar, ((amount).amount::numeric) / 100::numeric));
    """

    execute "DROP TYPE public.old_money_with_currency;"
  end

  def down do
    execute "ALTER TYPE money_with_currency RENAME TO new_money_with_currency;"
    execute "CREATE TYPE public.money_with_currency AS (amount integer, currency_code varchar);"

    execute """
    ALTER TABLE money_transfers
      ALTER COLUMN amount
      TYPE public.money_with_currency USING (((amount).amount::integer * 100, 'EUR'::varchar));
    """

    execute "DROP TYPE public.new_money_with_currency;"
  end
end
