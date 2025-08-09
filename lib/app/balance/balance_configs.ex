defmodule App.Balance.BalanceConfigs do
  @moduledoc """
  The configuration related to balancing.

  To know more about the balance config lifecycle, see `App.Balance.BalanceConfig`.
  """
  import Ecto.Query

  alias App.Accounts.User
  alias App.Balance.BalanceConfig
  alias App.Books.BookMember
  alias App.Repo
  alias App.Transfers.Peer

  @doc """
  Get the balance configuration of a member.

  Returns `nil` if the member has no balance configuration.
  """
  @spec get_balance_config_of_member(BookMember.t()) :: BalanceConfig.t() | nil
  def get_balance_config_of_member(%BookMember{balance_config_id: nil} = _member), do: nil

  def get_balance_config_of_member(%BookMember{} = member) do
    Repo.get!(BalanceConfig, member.balance_config_id)
  end

  @doc """
  Check if a member has revenues set in their balance configuration.

  Returns `false` both if the member has no balance configuration or if the balance
  configuration has no revenues set.
  """
  @spec member_has_revenues?(BookMember.t()) :: boolean()
  def member_has_revenues?(%BookMember{balance_config_id: nil} = _member), do: false

  def member_has_revenues?(%BookMember{} = member) do
    from(balance_config in BalanceConfig,
      where: balance_config.id == ^member.balance_config_id,
      select: not is_nil(balance_config.revenues)
    )
    |> Repo.one!()
  end

  ## Update revenues

  @spec create_balance_config(BookMember.t(), User.t(), map()) ::
          {:ok, BalanceConfig.t()} | {:error, Ecto.Changeset.t()}
  def create_balance_config(%BookMember{} = member, %User{} = owner, attrs) do
    former_balance_config = get_balance_config_of_member(member)

    changeset =
      %BalanceConfig{owner_id: owner.id}
      |> BalanceConfig.revenues_changeset(attrs)

    result =
      Ecto.Multi.new()
      |> Ecto.Multi.insert(:balance_config, changeset)
      |> Ecto.Multi.update(:member, fn %{balance_config: balance_config} ->
        BookMember.change_balance_config(member, balance_config)
      end)
      |> Ecto.Multi.run(:delete_old_config, fn _repo, _changes ->
        if former_balance_config, do: try_to_delete_balance_config(former_balance_config)
        {:ok, nil}
      end)
      |> Repo.transact()

    case result do
      {:ok, %{balance_config: balance_config}} -> {:ok, balance_config}
      {:error, :balance_config, changeset, _changes} -> {:error, changeset}
    end
  end

  defp try_to_delete_balance_config(%BalanceConfig{} = balance_config) do
    balance_config
    |> Ecto.Changeset.cast(%{}, [])
    |> Ecto.Changeset.foreign_key_constraint(:book_members,
      name: "book_members_balance_config_id_fkey"
    )
    |> Ecto.Changeset.foreign_key_constraint(:peers,
      name: "transfers_peers_balance_config_id_fkey"
    )
    |> Repo.delete(mode: :savepoint)
  end

  @doc """
  Link a balance configuration to a list of peers.
  """
  @spec link_balance_config_to_peers(BalanceConfig.t(), [Peer.t()]) :: :ok
  def link_balance_config_to_peers(%BalanceConfig{} = balance_config, peers) do
    peer_ids = Enum.map(peers, & &1.id)

    {_, nil} =
      from([peer: peer] in Peer.base_query(), where: peer.id in ^peer_ids)
      |> Repo.update_all(set: [balance_config_id: balance_config.id])

    :ok
  end

  @doc """
  Return an `%Ecto.Changeset{}` for tracking changes to a balance config revenues.
  """
  @spec change_balance_config_revenues(BalanceConfig.t(), map()) :: Ecto.Changeset.t()
  def change_balance_config_revenues(balance_config, attrs \\ %{}) do
    BalanceConfig.revenues_changeset(balance_config, attrs)
  end
end
