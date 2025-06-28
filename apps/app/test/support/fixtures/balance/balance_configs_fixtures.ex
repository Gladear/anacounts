defmodule App.Balance.BalanceConfigsFixtures do
  @moduledoc """
  Fixtures for the `App.Balance.BalanceConfigs` context
  """

  import Ecto.Query

  alias App.Balance.BalanceConfig
  alias App.Books.BookMember
  alias App.Repo

  def balance_config_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      owner_id: nil,
      revenues: 1234
    })
  end

  def balance_config_fixture(attrs \\ %{}) do
    BalanceConfig
    |> struct!(balance_config_attributes(attrs))
    |> Repo.insert!()
  end

  def member_balance_config_fixture(member, attrs \\ %{}) do
    {:ok, %{balance_config: balance_config}} =
      Ecto.Multi.new()
      |> Ecto.Multi.insert(
        :balance_config,
        BalanceConfig.revenues_changeset(
          %BalanceConfig{},
          balance_config_attributes(attrs)
        )
      )
      |> Ecto.Multi.update_all(
        :member,
        fn %{balance_config: balance_config} ->
          from(BookMember,
            where: [id: ^member.id],
            update: [set: [balance_config_id: ^balance_config.id]]
          )
        end,
        []
      )
      |> Repo.transact()

    balance_config
  end
end
