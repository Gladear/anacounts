defmodule App.Repo.Migrations.DeleteEmptyBalanceConfigs do
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
    repo().delete_all(from b in "balance_configs", where: b.id in ^batch_of_ids)
  end

  defp page_query do
    from b in "balance_configs",
      where: is_nil(b.annual_income),
      limit: @batch_size,
      select: b.id
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
