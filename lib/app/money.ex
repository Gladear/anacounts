defmodule App.Money do
  @moduledoc """
  Arithmetic and display helpers for EUR amounts stored as Decimal.
  """

  alias AppWeb.Cldr

  @currency_scale 2

  @spec round_amount(Decimal.decimal()) :: Decimal.t()
  defp round_amount(amount) do
    Decimal.round(amount, @currency_scale)
  end

  @doc """
  Multiply amount by a factor, and round to currency precision.
  """
  @spec mult(Decimal.decimal(), Decimal.decimal()) :: Decimal.t()
  def mult(amount, factor) do
    amount |> Decimal.mult(factor) |> round_amount()
  end

  @doc """
  Format a Decimal as a localized EUR currency string.
  """
  @spec to_string(Decimal.t()) :: String.t()
  def to_string(amount) do
    Cldr.Number.to_string!(amount, currency: :EUR, format: :currency)
  end

  @doc """
  Parse a user-supplied string (e.g. \"100.00\") into a Decimal.
  Returns nil on failure.
  """
  @spec parse(String.t()) :: Decimal.t() | nil
  def parse(string) when is_binary(string) do
    case Decimal.parse(string) do
      {decimal, ""} -> round_amount(decimal)
      _ -> nil
    end
  end
end
