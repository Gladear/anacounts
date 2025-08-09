defmodule AppWeb.DateFormatHelpers do
  @moduledoc """
  Convenience functions for formatting dates.
  """

  @preferred_date "%d-%m-%Y"

  @doc """
  Formats received datetime into a string.

  The datetime can be any of the Calendar types (`Time`, `Date`, `NaiveDateTime`, and
  `DateTime`) or any map, as long as they contain all of the relevant fields necessary
  for formatting - `:year`, `:month` and `:day`.

  ## Examples

      iex> format_date(~D[2019-01-01])
      "01-01-2019"

      iex> format_date(~N[2019-01-01 00:00:00])
      "01-01-2019"

      iex> format_date(%{year: 2019, month: 1, day: 1})
      "01-01-2019"

      iex> format_date(~T[00:00:00])
      ** (KeyError)

  """
  @spec format_date(map()) :: String.t()
  def format_date(date) do
    Calendar.strftime(date, "%x", preferred_date: @preferred_date)
  end
end
