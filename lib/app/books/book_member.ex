defmodule App.Books.BookMember do
  @moduledoc """
  The link between a book and a user.
  It contains the role of the user for this particular book.
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
          role: :creator | :member,
          user_id: User.id() | nil,
          user: User.t() | nil,
          deleted_at: NaiveDateTime.t() | nil,
          nickname: String.t(),
          email: String.t(),
          balance_config_id: BalanceConfig.id() | nil,
          balance: Money.t() | nil,
          balance_errors: [String.t()],
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  schema "book_members" do
    belongs_to :book, Book
    field :role, Ecto.Enum, values: [:creator, :member]

    belongs_to :user, User

    field :deleted_at, :naive_datetime

    # When the member is not linked to a user, the display name falls back to the book
    # member's `:nickname`, set at creation
    field :nickname, :string

    # Filled with the user `:email` if there is one
    field :email, :string, virtual: true

    # the current balance configuration for this member
    field :balance_config_id, :integer
    # Filled by the `Balance` context. If the `:balance_errors` is set,  the balance
    # was not computed correctly.
    field :balance, Money.Ecto.Composite.Type, virtual: true
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
  Updates an `%Ecto.Query{}` to select the `:email` of book members.
  """
  @spec select_email(Ecto.Query.t()) :: Ecto.Query.t()
  def select_email(query) do
    from [user: user] in join_user(query),
      select_merge: %{email: user.email}
  end

  defp join_user(query) do
    with_named_binding(query, :user, fn query ->
      from [book_member: book_member] in query,
        left_join: user in assoc(book_member, :user),
        as: :user
    end)
  end
end
