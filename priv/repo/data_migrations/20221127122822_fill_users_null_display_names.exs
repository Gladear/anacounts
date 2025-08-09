defmodule App.Repo.Migrations.FillUsersNullDisplayNames do
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
    {_updated, results} =
      repo().update_all(
        from(u in "users", select: u.id, where: u.id in ^batch_of_ids),
        [set: [display_name: "Undefined"]],
        log: :info
      )

    not_updated =
      MapSet.difference(MapSet.new(batch_of_ids), MapSet.new(results)) |> MapSet.to_list()

    Enum.each(not_updated, &handle_non_update/1)
    results
  end

  defp page_query(last_id) do
    from u in "users",
      select: u.id,
      where: is_nil(u.display_name) and u.id > ^last_id,
      order_by: [asc: u.id],
      limit: @batch_size
  end

  # If you have BigInt or Int IDs, fallback last_pos = 0
  # If you have UUID IDs, fallback last_pos = "00000000-0000-0000-0000-000000000000"
  defp throttle_change_in_batches(query_fun, change_fun, last_pos \\ 0)
  defp throttle_change_in_batches(_query_fun, _change_fun, nil), do: :ok

  defp throttle_change_in_batches(query_fun, change_fun, last_pos) do
    case repo().all(query_fun.(last_pos), log: :info, timeout: :infinity) do
      [] ->
        :ok

      ids ->
        results = change_fun.(ids)
        next_page = List.last(results)
        Process.sleep(@throttle_ms)
        throttle_change_in_batches(query_fun, change_fun, next_page)
    end
  end

  defp handle_non_update(id) do
    raise "#{inspect(id)} was not updated"
  end
end
