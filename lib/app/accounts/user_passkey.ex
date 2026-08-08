defmodule App.Accounts.UserPasskey do
  @moduledoc """
  A WebAuthn passkey credential belonging to a user.
  """

  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query

  alias App.Accounts.User

  @type t :: %__MODULE__{
          id: integer(),
          user_id: User.id(),
          device_name: String.t(),
          sign_count: non_neg_integer(),
          credential_id: binary(),
          public_key: binary(),
          aaguid: binary() | nil,
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  @type built_t :: %__MODULE__{id: nil}

  schema "user_passkeys" do
    field :user_id, :integer, writable: :insert

    field :device_name, :string

    # WebAuthn authentication, see `App.Accounts.WebAuthn` for details
    field :credential_id, :binary, writable: :insert
    field :public_key, :binary, writable: :insert
    field :aaguid, :binary, writable: :insert
    # Counter incremented by the authenticator on each use, checked to
    # detect cloned/replayed credentials
    field :sign_count, :integer

    timestamps()
  end

  ## Changesets

  def device_name_changeset(passkey, attrs) do
    passkey
    |> cast(attrs, [:device_name])
    |> validate_device_name()
  end

  defp validate_device_name(changeset) do
    changeset
    |> validate_required(:device_name)
    |> validate_length(:device_name, max: 255)
  end

  def change_sign_count_changeset(passkey, sign_count)
      when is_integer(sign_count) and sign_count >= 0 do
    change(passkey, sign_count: sign_count)
  end

  ## Queries

  @doc """
  Returns an `%Ecto.Query{}` fetching all user passkeys.
  """
  @spec base_query() :: Ecto.Query.t()
  def base_query do
    from user_passkey in __MODULE__,
      as: :user_passkey
  end

  @doc """
  Returns an `%Ecto.Query{}` fetching all user passkeys of a given user.
  """
  @spec user_query(Ecto.Queryable.t(), User.t()) :: Ecto.Query.t()
  def user_query(query \\ base_query(), %User{} = user) do
    from [user_passkey: user_passkey] in query,
      where: user_passkey.user_id == ^user.id
  end
end
