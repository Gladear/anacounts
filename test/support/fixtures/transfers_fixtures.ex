defmodule App.TransfersFixtures do
  @moduledoc """
  Fixtures for the `App.Transfers` context
  """

  alias App.Repo
  alias App.Transfers.MoneyTransfer
  alias App.Transfers.Peer

  def money_transfer_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      label: "This is a money transfer",
      amount: Money.new!(:EUR, 1799),
      date: ~D[2022-06-23],
      type: :payment,
      balance_means: :divide_equally
    })
  end

  def money_transfer_fixture(book, attrs \\ %{}) do
    %MoneyTransfer{book_id: book.id}
    |> Map.merge(money_transfer_attributes(attrs))
    |> Repo.insert!()
  end

  def peer_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      weight: Decimal.new(1)
    })
  end

  def peer_fixture(transfer, attrs) do
    %Peer{transfer_id: transfer.id}
    |> Map.merge(peer_attributes(attrs))
    |> Repo.insert!()
  end
end
