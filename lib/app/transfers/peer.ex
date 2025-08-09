defmodule App.Transfers.Peer do
  @moduledoc """
  The entity linking money transfers to book members.
  """

  use Ecto.Schema

  import Ecto.Query

  alias App.Balance.BalanceConfig
  alias App.Books.BookMember
  alias App.Transfers.MoneyTransfer

  @type id :: integer()
  @type t :: %__MODULE__{
          id: id(),
          transfer: MoneyTransfer.t(),
          member: BookMember.t(),
          weight: Decimal.t(),
          balance_config: BalanceConfig.t() | nil,
          balance_config_id: BalanceConfig.id() | nil,
          total_weight: Decimal.t() | nil
        }

  schema "transfers_peers" do
    belongs_to :transfer, MoneyTransfer
    belongs_to :member, BookMember

    field :weight, :decimal, default: Decimal.new(1)

    belongs_to :balance_config, BalanceConfig
    # The sum of all the peer weight. Depends on the transfer balance means
    field :total_weight, :decimal, virtual: true
  end

  ## Queries

  @doc """
  Returns an `%Ecto.Query{}` fetching all peers.
  """
  @spec base_query() :: Ecto.Query.t()
  def base_query do
    from peer in __MODULE__, as: :peer
  end

  @doc """
  Returns an `%Ecto.Query{}` fetching all peers of a given money transfer.
  """
  @spec transfer_query(Ecto.Queryable.t(), MoneyTransfer.t()) :: Ecto.Query.t()
  def transfer_query(query \\ base_query(), %MoneyTransfer{} = transfer) do
    from [peer: peer] in query,
      where: peer.transfer_id == ^transfer.id
  end
end
