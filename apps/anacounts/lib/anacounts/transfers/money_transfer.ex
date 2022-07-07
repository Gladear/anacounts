defmodule Anacounts.Transfers.MoneyTransfer do
  @moduledoc """
  Entity representing money transfers. This includes both payments,
  incomes and reimbursements.
  """

  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query

  alias Anacounts.Accounts
  alias Anacounts.Transfers

  # the types
  @transfer_types [:payment, :income, :reimbursement]

  @type id :: integer()
  @type t :: %__MODULE__{
          id: id(),
          amount: Money.t(),
          type: :payment | :income | :reimbursement,
          book: Accounts.Book.t(),
          holder: Accounts.BookMember.t(),
          peers: Transfers.Peer.t()
        }

  schema "transfers_money_transfers" do
    field :label, :string
    field :amount, Money.Ecto.Composite.Type
    field :type, Ecto.Enum, values: @transfer_types
    field :date, :utc_datetime

    belongs_to :book, Accounts.Book
    belongs_to :holder, Accounts.BookMember

    has_many :peers, Transfers.Peer,
      foreign_key: :transfer_id,
      on_replace: :delete_if_exists

    timestamps()
  end

  def create_changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, [:label, :amount, :type, :date, :book_id, :holder_id])
    |> validate_label()
    |> validate_required(:amount)
    |> validate_type()
    |> validate_book_id()
    |> validate_holder_id()
    |> cast_assoc(:peers, with: &Transfers.Peer.create_money_transfer_changeset/2)
  end

  def update_changeset(struct, attrs) do
    struct
    |> cast(attrs, [:label, :amount, :type, :date])
    |> validate_label()
    |> validate_required(:amount)
    |> validate_type()
    |> cast_assoc(:peers, with: &Transfers.Peer.update_money_transfer_changeset/2)
  end

  defp validate_label(changeset) do
    changeset
    |> validate_required(:label)
    |> validate_length(:label, min: 1, max: 255)
  end

  defp validate_book_id(changeset) do
    changeset
    |> validate_required(:book_id)
    |> foreign_key_constraint(:book_id)
  end

  defp validate_holder_id(changeset) do
    changeset
    |> validate_required(:holder_id)
    |> foreign_key_constraint(:holder_id)
  end

  defp validate_type(changeset) do
    changeset
    |> validate_inclusion(:type, @transfer_types)
  end

  def base_query do
    from __MODULE__, as: :money_transfer
  end

  def where_book_id(query, book_id) do
    from [money_transfer: money_transfer] in query,
      where: money_transfer.book_id == ^book_id
  end
end
