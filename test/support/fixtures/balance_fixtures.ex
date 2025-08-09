defmodule App.BalanceFixtures do
  @moduledoc """
  Fixtures for the `App.Balance` context
  """

  def transfer_params_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      means_code: :divide_equally,
      params: nil
    })
  end
end
