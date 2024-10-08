defmodule App.Books.BookMember do
  @moduledoc """
  The link between a book and a user.
  It contains the role of the user for this particular book.
  """
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias App.Accounts.User
  alias App.Balance
  alias App.Balance.BalanceConfig
  alias App.Books.Book

  @type id :: integer()

  @type t :: %__MODULE__{
          id: id() | nil,
          book_id: Book.id() | nil,
          book: Book.t() | Ecto.Association.NotLoaded.t(),
          role: :creator | :member | nil,
          user_id: User.id() | Ecto.Association.NotLoaded.t() | nil,
          user: User.t() | Ecto.Association.NotLoaded.t() | nil,
          deleted_at: NaiveDateTime.t() | nil,
          nickname: String.t() | nil,
          email: String.t() | nil,
          balance_config_id: BalanceConfig.id() | nil,
          balance_config: BalanceConfig.t() | Ecto.Association.NotLoaded.t() | nil,
          balance: Money.t() | {:error, Balance.error_reasons()} | nil,
          inserted_at: NaiveDateTime.t() | nil,
          updated_at: NaiveDateTime.t() | nil
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
    belongs_to :balance_config, BalanceConfig
    # Filled by the `Balance` context. Maybe be set to `{:error, reasons}` if the
    # balance cannot be computed.
    field :balance, Money.Ecto.Composite.Type, virtual: true

    timestamps()
  end

  ## Changesets

  @spec nickname_changeset(t(), map()) :: Ecto.Changeset.t()
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
