defmodule App.Repo.Migrations.CreateUsersBalanceConfig do
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
    repo().insert_all("balance_configs", Enum.map(batch_of_ids, &%{user_id: &1}))
  end

  defp page_query do
    from u in "users",
      select: u.id,
      left_join: b in "balance_configs",
      on: b.user_id == u.id,
      where: is_nil(b.id),
      limit: @batch_size
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
