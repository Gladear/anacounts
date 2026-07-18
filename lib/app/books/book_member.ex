defmodule App.Books.BookMember do
  @moduledoc """
  The link between a book and a user.
  """
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias App.Accounts.User
  alias App.Balance.BalanceConfig
  alias App.Books.Book

  @type id :: integer()

  @type t :: %__MODULE__{
          id: id(),
          book_id: Book.id(),
          book: Book.t(),
          user_id: User.id() | nil,
          user: User.t() | nil,
          archived_at: NaiveDateTime.t() | nil,
          nickname: String.t(),
          balance_config_id: BalanceConfig.id() | nil,
          balance: Decimal.t() | nil,
          balance_errors: [String.t()],
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  schema "book_members" do
    belongs_to :book, Book

    belongs_to :user, User

    field :archived_at, :naive_datetime

    # When the member is not linked to a user, the display name falls back to the book
    # member's `:nickname`, set at creation
    field :nickname, :string

    # the current balance configuration for this member
    field :balance_config_id, :integer
    # Filled by the `Balance` context. If the `:balance_errors` is set,  the balance
    # was not computed correctly.
    field :balance, :decimal, virtual: true
    field :balance_errors, {:array, :string}, virtual: true, default: []

    timestamps()
  end

  ## Changesets

  def nickname_changeset(struct, attrs) do
    struct
    |> cast(attrs, [:nickname])
    |> validate_nickname()
  end

  defp validate_nickname(changeset) do
    changeset
    |> validate_required(:nickname)
    |> validate_length(:nickname, min: 1, max: 255)
  end

  @spec change_balance_config(t(), BalanceConfig.t()) :: Ecto.Changeset.t()
  def change_balance_config(struct, %BalanceConfig{} = balance_config) do
    change(struct, balance_config_id: balance_config.id)
  end

  @doc """
  Returns a changeset to archive a book member.
  """
  @spec archive_changeset(t()) :: Ecto.Changeset.t()
  def archive_changeset(book_member) do
    now = NaiveDateTime.utc_now(:second)
    change(book_member, archived_at: now)
  end

  @doc """
  Returns a changeset to unarchive a book member.
  """
  @spec unarchive_changeset(t()) :: Ecto.Changeset.t()
  def unarchive_changeset(book_member) do
    change(book_member, archived_at: nil)
  end

  ## Queries

  @doc """
  Returns an `%Ecto.Query{}` fetching all book members.
  """
  @spec base_query() :: Ecto.Query.t()
  def base_query do
    from __MODULE__, as: :book_member
  end

  @doc """
  Returns an `%Ecto.Query{}` fetching all book members of a given book.
  """
  @spec book_query(Ecto.Queryable.t(), Book.t()) :: Ecto.Query.t()
  def book_query(query \\ base_query(), book) do
    from [book_member: book_member] in query,
      where: book_member.book_id == ^book.id
  end

  @doc """
  Filters down an `%Ecto.Query{}` to only return non-archived book members.
  """
  @spec non_archived_query(Ecto.Queryable.t()) :: Ecto.Query.t()
  def non_archived_query(query) do
    from [book_member: book_member] in query,
      where: is_nil(book_member.archived_at)
  end
end
