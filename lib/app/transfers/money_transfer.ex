defmodule App.Transfers.MoneyTransfer do
  @moduledoc """
  Entity representing money transfers. This includes both payments,
  incomes and reimbursements.
  """

  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query

  alias App.Books.Book
  alias App.Books.BookMember
  alias App.Transfers.Peer

  @type id :: integer()
  @type t :: %__MODULE__{
          id: id(),
          label: String.t(),
          amount: Money.t(),
          type: type(),
          date: Date.t(),
          book_id: Book.id(),
          creator_id: BookMember.id(),
          tenant: BookMember.t(),
          tenant_id: BookMember.id(),
          balance_means: balance_means(),
          peers: [Peer.t()],
          total_peer_weight: Decimal.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  # TODO rename transfer.type to transfer.kind

  @type type :: :payment | :income | :reimbursement
  @transfer_types [:payment, :income, :reimbursement]

  @type balance_means :: :divide_equally | :weight_by_revenues
  @balance_means [:divide_equally, :weight_by_revenues]

  schema "money_transfers" do
    field :label, :string
    field :amount, Money.Ecto.Composite.Type
    field :type, Ecto.Enum, values: @transfer_types
    field :date, :date, read_after_writes: true

    field :book_id, :integer
    field :creator_id, :integer
    belongs_to :tenant, BookMember

    # balance
    field :balance_means, Ecto.Enum, values: @balance_means

    has_many :peers, Peer,
      foreign_key: :transfer_id,
      on_replace: :delete_if_exists

    # The current peer is used in some operations, like when updating the revenues,
    # in the "transfers" step, to know the link between the current member and the transfer.
    field :current_peer, :map, virtual: true

    # Sum of all the peer `:total_weight`. Depends on the transfer balance means
    field :total_peer_weight, :decimal, virtual: true

    timestamps()
  end

  ## Changesets

  def changeset(struct, attrs) do
    struct
    |> cast(attrs, [:label, :date, :balance_means, :tenant_id, :amount])
    |> validate_label()
    |> validate_balance_means()
    |> validate_tenant_id()
    |> validate_amount()
    |> cast_assoc(:peers, with: &Ecto.Changeset.cast(&1, &2, [:member_id, :weight]))
  end

  @doc """
  Changeset for creating a reimbursement kind of money transfer.
  """
  def reimbursement_changeset(struct, attrs) do
    struct
    |> cast(attrs, [:label, :amount, :date, :tenant_id])
    |> validate_label()
    |> validate_amount()
    |> cast_assoc(:peers, with: &Ecto.Changeset.cast(&1, &2, [:member_id]))
    |> validate_reimbursement_peers()
  end

  defp validate_label(changeset) do
    changeset
    |> validate_required(:label)
    |> validate_length(:label, min: 1, max: 255)
  end

  defp validate_amount(changeset) do
    changeset
    |> validate_required(:amount)
  end

  defp validate_tenant_id(changeset) do
    changeset
    |> validate_required(:tenant_id)
    |> foreign_key_constraint(:tenant_id)
  end

  defp validate_balance_means(changeset) do
    changeset
    |> validate_required(:balance_means)
  end

  defp validate_reimbursement_peers(changeset) do
    tenant_id = Ecto.Changeset.fetch_field!(changeset, :tenant_id)

    changeset
    |> validate_change(:peers, fn :peers, peers ->
      case peers do
        [_one_peer] -> []
        _peers -> raise Ecto.ChangeError, "A reimbursement must have exactly one peer"
      end
    end)
    |> validate_change(:peers, fn :peers, [peer] ->
      peer_member_id = Ecto.Changeset.fetch_field!(peer, :member_id)

      if peer_member_id == tenant_id,
        do: [tenant_id: "cannot be the same as the debtor"],
        else: []
    end)
  end

  ## Queries

  # create a simple query with named binding
  defp base_query do
    from __MODULE__, as: :money_transfer
  end

  @doc """
  Get all money transfers within a book.
  """
  @spec transfers_of_book_query(Book.t()) :: Ecto.Query.t()
  def transfers_of_book_query(book) do
    from [money_transfer: money_transfer] in base_query(),
      where: money_transfer.book_id == ^book.id
  end
end
