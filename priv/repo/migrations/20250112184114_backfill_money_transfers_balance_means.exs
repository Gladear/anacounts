defmodule App.Repo.Migrations.BackfillMoneyTransfersBalanceMeans do
  use Ecto.Migration

  import Ecto.Query

  @disable_ddl_transaction true
  @disable_migration_lock true
  @batch_size 50
  @throttle_ms 500

  def up do
    throttle_change_in_batches(&page_query/0, &do_change/1)
  end

  def down, do: :ok

  defp do_change(batch_of_ids) do
    from(t in "money_transfers",
      where: t.id in ^batch_of_ids,
      update: [
        set: [
          balance_means:
            fragment(
              "CASE (?).means_code WHEN 'divide_equally' THEN 'divide_equally' :: balance_means WHEN 'weight_by_income' THEN 'weight_by_income' :: balance_means END",
              t.balance_params
            )
        ]
      ]
    )
    |> repo().update_all([], log: :info, timeout: :infinity)
  end

  defp page_query do
    from t in "money_transfers",
      where: is_nil(t.balance_means),
      order_by: [asc: t.id],
      limit: @batch_size,
      select: t.id
  end

  defp throttle_change_in_batches(query_fun, change_fun) do
    case repo().all(query_fun.(), log: :info, timeout: :infinity) do
      [] ->
        :ok

      ids ->
        change_fun.(ids)
        Process.sleep(@throttle_ms)
        throttle_change_in_batches(query_fun, change_fun)
    end
  end
end
