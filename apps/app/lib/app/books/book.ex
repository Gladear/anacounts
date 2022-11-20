defmodule App.Books.Book do
  @moduledoc """
  The entity grouping users and transfers.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias App.Balance.TransferParams

  @type id :: integer()
  @type t :: %__MODULE__{
          id: id(),
          name: String.t(),
          deleted_at: NaiveDateTime.t(),
          default_balance_params: TransferParams.t(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  schema "books" do
    field :name, :string
    field :deleted_at, :naive_datetime

    # balance
    field :default_balance_params, TransferParams

    timestamps()
  end

  ## Changeset

  def changeset(struct, attrs) do
    struct
    |> cast(attrs, [:name, :default_balance_params])
    |> validate_name()
    |> validate_default_balance_params()
  end

  defp validate_name(changeset) do
    changeset
    |> validate_required(:name)
    |> validate_length(:name, max: 255)
  end

  defp validate_default_balance_params(changeset) do
    changeset
    |> validate_required(:default_balance_params)
  end

  def delete_changeset(book) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    change(book, deleted_at: now)
  end
end
