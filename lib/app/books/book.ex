defmodule App.Books.Book do
  @moduledoc """
  The entity grouping users and transfers.
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  @type id :: integer()
  @type t :: %__MODULE__{
          id: id(),
          name: String.t(),
          closed_at: NaiveDateTime.t() | nil,
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  schema "books" do
    field :name, :string
    field :closed_at, :naive_datetime

    timestamps()
  end

  ## Changeset

  def name_changeset(struct, attrs) do
    struct
    |> cast(attrs, [:name])
    |> validate_name()
  end

  defp validate_name(changeset) do
    changeset
    |> validate_required(:name)
    |> validate_length(:name, max: 255)
  end

  @doc """
  Returns a changeset to close a book.
  """
  @spec close_changeset(t()) :: Ecto.Changeset.t()
  def close_changeset(book) do
    now = NaiveDateTime.utc_now(:second)
    change(book, closed_at: now)
  end

  @doc """
  Returns a changeset to re-open a book.
  """
  @spec reopen_changeset(t()) :: Ecto.Changeset.t()
  def reopen_changeset(book) do
    change(book, closed_at: nil)
  end

  ## Queries

  @spec base_query() :: Ecto.Query.t()
  def base_query do
    from book in __MODULE__,
      as: :book
  end
end
