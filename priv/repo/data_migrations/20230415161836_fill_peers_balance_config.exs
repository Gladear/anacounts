defmodule App.Repo.Migrations.FillPeersBalanceConfig do
  use Ecto.Migration

  import Ecto.Query

  @disable_ddl_transaction true
  @disable_migration_lock true
  @batch_size 50
  @throttle_ms 500

  def up do
    throttle_change_in_batches(&page_query/1, &do_change/1)
  end

  def down, do: :ok

  defp do_change(batch_of_ids) do
    from(p in "transfers_peers",
      where: p.id in ^batch_of_ids,
      join: m in "book_members",
      on: m.id == p.member_id,
      update: [set: [balance_config_id: m.balance_config_id]]
    )
    |> repo().update_all([], log: :info, timeout: :infinity)
  end

  defp page_query(last_id) do
    from p in "transfers_peers",
      where: p.id > ^last_id,
      order_by: [asc: p.id],
      limit: @batch_size,
      select: p.id
  end

  defp throttle_change_in_batches(query_fun, change_fun, last_pos \\ 0)
  defp throttle_change_in_batches(_query_fun, _change_fun, nil), do: :ok

  defp throttle_change_in_batches(query_fun, change_fun, last_pos) do
    case repo().all(query_fun.(last_pos), log: :info, timeout: :infinity) do
      [] ->
        :ok

      ids ->
        change_fun.(ids)
        next_page = List.last(ids)
        Process.sleep(@throttle_ms)
        throttle_change_in_batches(query_fun, change_fun, next_page)
    end
  end
end
