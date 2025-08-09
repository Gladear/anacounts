defmodule App.Balance.BalanceError do
  @moduledoc """
  Balance errors are instantiated when the balance of a book cannot be computed,
  and are used to store the kind of error along with some extra information.
  """
  use Ecto.Schema

  @type t :: %__MODULE__{
          kind: atom(),
          extra: map(),
          uniq_hash: String.t(),
          private: map()
        }

  @primary_key false
  embedded_schema do
    field :kind, Ecto.Enum, values: [:revenues_missing]
    field :extra, :map

    field :uniq_hash, :string, virtual: true
    field :private, :map, virtual: true, default: %{}
  end

  @spec new(kind :: atom(), extra :: map()) :: t()
  def new(kind, extra) when is_atom(kind) and is_map(extra) do
    %__MODULE__{
      kind: kind,
      extra: extra,
      uniq_hash: uniq_hash(kind, extra)
    }
  end

  defp uniq_hash(:revenues_missing, extra) do
    "revenues_missing_#{extra.member_id}"
  end
end
