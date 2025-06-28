defmodule App.Transfers do
  @moduledoc """
  Context for money transfers.
  """

  import Ecto.Query

  alias App.Books.Book
  alias App.Books.BookMember
  alias App.Repo
  alias App.Transfers.MoneyTransfer
  alias App.Transfers.Peer

  ## Database getters

  @doc """
  Gets a single money_transfer.

  Raises `Ecto.NoResultsError` if the Money transfer does not exist.
  """
  def get_money_transfer!(id), do: Repo.get!(MoneyTransfer, id)

  @doc """
  Gets a single money_transfer, if they belong to a book.

  Raises `Ecto.NoResultsError` if the Money transfer does not exist.
  """
  def get_money_transfer_of_book!(id, %Book{} = book),
    do: Repo.get_by!(MoneyTransfer, id: id, book_id: book.id)

  @doc """
  Find all money transfers of a book.

  The result may be filtered by passing a options.

  ## Options

  - `:filters` - a map of filters to apply to the query. See the `Filters` section below.
  - `:offset` - the offset of the query
  - `:limit` - the limit of the query

  ## Filters

  - `:sort_by` - the field to sort by, one of :most_recent, :oldest, :last_created or
    :first_created
  - `:tenanted_by` - the tenancy of the transfer, one of :anyone, a member id or
    `{:not, member_id}`
  """
  @spec list_transfers_of_book(Book.t(), Keyword.t()) :: [MoneyTransfer.t()]
  def list_transfers_of_book(%Book{} = book, opts \\ []) do
    filters = Keyword.get(opts, :filters, %{})
    offset = Keyword.get(opts, :offset, 0)
    limit = Keyword.get(opts, :limit, 25)

    MoneyTransfer.transfers_of_book_query(book)
    |> filter_money_transfers_query(filters)
    |> paginate_query(offset, limit)
    |> Repo.all()
  end

  @doc """
  Find all money transfers related to book members.
  """
  @spec list_transfers_of_members([BookMember.t()]) :: [MoneyTransfer.t()]
  def list_transfers_of_members(members) do
    members_id = Enum.map(members, fn %BookMember{} = member -> member.id end)

    from(money_transfer in MoneyTransfer,
      join: peer in assoc(money_transfer, :peers),
      where: peer.member_id in ^members_id,
      distinct: true
    )
    |> Repo.all()
  end

  ## Filters

  @filters_default %{
    tenanted_by: nil,
    created_by: nil,
    sort_by: :most_recent
  }
  @filters_types %{
    # Values are `nil`, `member_id` or `{:not, member_id}`
    tenanted_by: :any,
    created_by: {:array, :integer},
    sort_by:
      Ecto.ParameterizedType.init(Ecto.Enum,
        values: [:most_recent, :oldest, :last_created, :first_created]
      )
  }

  defp filter_money_transfers_query(query, raw_filters) do
    filters =
      {@filters_default, @filters_types}
      |> Ecto.Changeset.cast(raw_filters, Map.keys(@filters_types))
      |> Ecto.Changeset.apply_changes()

    query
    |> filter_money_transfers_by_tenancy(filters[:tenanted_by])
    |> filter_money_transfers_by_creator(filters[:created_by])
    |> sort_money_transfers_by(filters[:sort_by])
  end

  defp filter_money_transfers_by_tenancy(query, {:not, member_id}) when is_integer(member_id) do
    from [money_transfer: money_transfer] in query, where: money_transfer.tenant_id != ^member_id
  end

  defp filter_money_transfers_by_tenancy(query, member_id) when is_integer(member_id) do
    from [money_transfer: money_transfer] in query, where: money_transfer.tenant_id == ^member_id
  end

  defp filter_money_transfers_by_tenancy(query, nil), do: query

  defp filter_money_transfers_by_creator(query, creator_ids) when is_list(creator_ids) do
    from [money_transfer: money_transfer] in query,
      where: money_transfer.creator_id in ^creator_ids
  end

  defp filter_money_transfers_by_creator(query, nil), do: query

  defp sort_money_transfers_by(query, :most_recent) do
    from [money_transfer: money_transfer] in query, order_by: [desc: money_transfer.date]
  end

  defp sort_money_transfers_by(query, :oldest) do
    from [money_transfer: money_transfer] in query, order_by: [asc: money_transfer.date]
  end

  defp sort_money_transfers_by(query, :last_created) do
    from [money_transfer: money_transfer] in query, order_by: [desc: money_transfer.inserted_at]
  end

  defp sort_money_transfers_by(query, :first_created) do
    from [money_transfer: money_transfer] in query, order_by: [asc: money_transfer.inserted_at]
  end

  ## Pagination

  defp paginate_query(query, offset, limit) do
    query
    |> limit(^limit)
    |> offset(^offset)
  end

  ## CRUD

  @doc """
  Creates a money_transfer.
  """
  @spec create_money_transfer(Book.t(), BookMember.t(), MoneyTransfer.type(), map()) ::
          {:ok, MoneyTransfer.t()} | {:error, Ecto.Changeset.t()}
  def create_money_transfer(%Book{} = book, %BookMember{} = creator, type, attrs)
      when is_map(attrs) and type in [:payment, :income] do
    changeset =
      %MoneyTransfer{
        book_id: book.id,
        creator_id: creator.id,
        type: type
      }
      |> MoneyTransfer.changeset(attrs)

    result =
      Ecto.Multi.new()
      |> Ecto.Multi.insert(:money_transfer, changeset)
      |> Ecto.Multi.update_all(
        :update_peers_balance_config,
        fn %{money_transfer: money_transfer} ->
          from [peer: peer] in Peer.transfer_query(money_transfer),
            join: member in BookMember,
            on: peer.member_id == member.id,
            update: [set: [balance_config_id: member.balance_config_id]]
        end,
        []
      )
      |> Repo.transact()

    case result do
      {:ok, %{money_transfer: money_transfer}} -> {:ok, money_transfer}
      {:error, :money_transfer, changeset, _changes} -> {:error, changeset}
    end
  end

  @doc """
  Updates a money_transfer.
  """
  @spec update_money_transfer(MoneyTransfer.t(), map()) ::
          {:ok, MoneyTransfer.t()} | {:error, Ecto.Changeset.t()}
  def update_money_transfer(%MoneyTransfer{} = money_transfer, attrs) do
    money_transfer
    |> MoneyTransfer.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a money_transfer.
  """
  @spec delete_money_transfer(MoneyTransfer.t()) ::
          {:ok, MoneyTransfer.t()} | {:error, Ecto.Changeset.t()}
  def delete_money_transfer(%MoneyTransfer{} = money_transfer) do
    Repo.delete(money_transfer)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking money_transfer changes.
  """
  def change_money_transfer(%MoneyTransfer{} = money_transfer, attrs \\ %{}) do
    MoneyTransfer.changeset(money_transfer, attrs)
  end

  ## Reimbursements

  @doc """
  Creates a new reimbursement.
  """
  @spec create_reimbursement(Book.t(), map()) ::
          {:ok, MoneyTransfer.t()} | {:error, Ecto.Changeset.t()}
  def create_reimbursement(%Book{} = book, attrs) do
    %MoneyTransfer{
      book_id: book.id,
      type: :reimbursement,
      balance_means: :divide_equally
    }
    |> MoneyTransfer.reimbursement_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking reimbursement changes.
  """
  def change_reimbursement(%MoneyTransfer{} = money_transfer, attrs \\ %{}) do
    MoneyTransfer.reimbursement_changeset(money_transfer, attrs)
  end

  ## Status/fields

  # TODO Rework, a :payment should have a negative amount since it appears as negative to the user

  @doc """
  Retrieves the amount of money a money transfer costs or provides.
  """
  @spec amount(MoneyTransfer.t()) :: Money.t()
  def amount(money_transfer)
  def amount(%MoneyTransfer{type: :payment} = money_transfer), do: money_transfer.amount
  def amount(%MoneyTransfer{} = money_transfer), do: Money.negate!(money_transfer.amount)
end
