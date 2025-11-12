defmodule App.Balance.BalanceConfig do
  @moduledoc """
  A configuration entity containing data for balancing the money transfers. This therefore
  includes private data, which is encrypted in the database.

  Balance configurations are referenced by book members and peers. They can be referenced
  by multiple entities related to the same member at the same time. i.e. a peer linked to
  a member may share the same balance configuration as the member.

  ## Use case

  Balance configuration are created per member by the user linked to the member or,
  if the member is not linked to a user, by any user member of the book.

  When creating a new transfer, the peers inherit the balance configuration of their
  member.

  When a user updates the balance configuration of a member, a new balance configuration
  is created

  they are asked to choose
  which peer should inherit the new configuration.

  ## Confidential information

  Due to the nature of the data, the balance configurations' fields filled by the user
  are encrypted in the database using Cloak and Cloak.Ecto.

  This information should never be displayed to anyone but their owner. The owner is a
  user referenced by the `:owner` association. A balance configuration may not have a
  owner - e.g. if the user deleted their account.

  ## Lifecycle

  The lifecycle of a balance configuration depends on what entity they are referenced by.
  Note that they may be referenced by different entities, and that the entities
  referencing it may change during the lifetime of the configuration.

  The overall lifecycle of balance configurations was designed to answer two problems:
  - the balance configurations must have some kind of "history", so when the configuration
    of a member changes their revenues, the old configuration is kept and is still
    referenced by peers,
  - an unlinked book member must be able to have their own balance configuration.
    This allows both to have members without users in the first place, and users to
    leave book, leaving an independent book member thereafter.

  Note that the deletion of balance configs is handled in a different part of the
  documentation, being common to all entities.

  ### Book members

  When a book member is created, no configuration is created. However, the first balance
  configuration can be created for book members manually from this point.

  When the balance configuration of a member is updated, the old one is simply replaced by
  the new balance configuration. No history is kept, but the old configuration is still
  referenced by the peers linked to the member, unless the user chooses to link them to
  the new configuration (see [Peers](#peers)). When the update is done, if the old
  configuration isn't linked to any entity anymore, it is deleted.

  ### Peers

  When a peer is created through a money transfer, it is linked to the balance config of
  the linked member.

  When the balance configuration of a member is updated, the user is asked which peer
  should be linked to the new configuration. If some peers were not linked to a
  configuration, they are forced to be linked to the new one.

  ## Deletion

  A balance configuration can only be deleted if no entity references it. To make
  deletion the least painful possible, all entities referencing a balance config have
  their foreign key set to RESTRICT.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias App.Accounts.User

  @type id :: integer()

  @type t :: %__MODULE__{
          id: id(),
          owner: User.t(),
          owner_id: User.id(),
          revenues: non_neg_integer(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  @derive {Inspect, only: [:id, :owner, :owner_id]}
  schema "balance_configs" do
    belongs_to :owner, User

    # Confidential information
    field :revenues, App.Encrypted.Integer

    timestamps()
  end

  def revenues_changeset(struct, attrs) do
    struct
    |> cast(attrs, [:revenues])
    |> validate_revenues()
  end

  defp validate_revenues(changeset) do
    changeset
    |> validate_number(:revenues, greater_than_or_equal_to: 0)
  end
end
