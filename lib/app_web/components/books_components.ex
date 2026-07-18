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
      Decimal.negative?(book_member.balance) -> :red
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
      Decimal.negative?(book_member.balance) -> "text-red-500"
      true -> "text-green-500"
    end
  end

  defp balance_string(book_member) do
    if Balance.has_balance_error?(book_member) do
      "XX.XX"
    else
      App.Money.to_string(book_member.balance)
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

  ## Member avatars

  @doc """
  Display the avatar related to a book member.
  """
  attr :book_member, BookMember, required: true

  def book_member_avatar(assigns) do
    if has_user?(assigns.book_member) do
      ~H|<.avatar name={@book_member.nickname} />|
    else
      ~H|<.icon name={:user_circle} class="m-1" />|
    end
  end

  defp has_user?(book_member) do
    book_member.user_id != nil
  end

  @doc """
  A component to display a book member in a hero layout.

  Shows the member's initials avatar, nickname.
  """
  attr :book_member, BookMember, required: true

  def member_hero_avatar(assigns) do
    ~H"""
    <div class="text-center my-4">
      <.avatar name={@book_member.nickname} size={:hero} class="mx-auto" />
      <span class="label">{@book_member.nickname}</span>
    </div>
    """
  end

  @doc """
  Formats the date a book member joined, for display in a detail card.
  """
  @spec member_joined_at(BookMember.t()) :: String.t()
  def member_joined_at(%BookMember{} = book_member) do
    Localize.Date.to_string!(book_member.inserted_at, format: :long)
  end
end
