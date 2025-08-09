defmodule AppWeb.BooksComponents do
  @moduledoc """
  A module defining books specific components.
  """

  use AppWeb, :html

  alias App.Balance
  alias App.Books.BookMember

  ## Balance card

  @doc """
  A specialized card displaying the balance of a member.
  """
  attr :book_member, BookMember, required: true

  slot :extra_title

  def balance_card(assigns) do
    ~H"""
    <.card color={balance_card_color(@book_member)}>
      <:title>Balance {render_slot(@extra_title)}</:title>
      {balance_string(@book_member)}
    </.card>
    """
  end

  defp balance_card_color(book_member) do
    cond do
      Balance.has_balance_error?(book_member) -> :neutral
      Money.negative?(book_member.balance) -> :red
      true -> :green
    end
  end

  @doc """
  The book member balance displayed as a colorized text.
  """
  attr :book_member, BookMember, required: true

  def balance_text(assigns) do
    ~H"""
    <span class={["label", balance_text_class(@book_member)]}>
      {balance_string(@book_member)}
    </span>
    """
  end

  defp balance_text_class(book_member) do
    cond do
      Balance.has_balance_error?(book_member) -> "text-neutral-500"
      Money.negative?(book_member.balance) -> "text-red-500"
      true -> "text-green-500"
    end
  end

  defp balance_string(book_member) do
    if Balance.has_balance_error?(book_member) do
      "XX.XX"
    else
      Money.to_string!(book_member.balance)
    end
  end

  @doc """
  Similar to `balance_card/1`, this component includes a link
  to the balance page of the book.
  """
  attr :book_member, BookMember, required: true

  def balance_card_link(assigns) do
    ~H"""
    <.link navigate={~p"/books/#{@book_member.book_id}/balance"}>
      <.balance_card book_member={@book_member}>
        <:extra_title><.icon name={:chevron_right} /></:extra_title>
      </.balance_card>
    </.link>
    """
  end
end
