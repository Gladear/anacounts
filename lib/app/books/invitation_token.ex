defmodule App.Books.InvitationToken do
  @moduledoc """
  A schema for book invitation tokens.

  Tokens are linked to a book, and can be used to invite a user to join it.
  Currently, tokens do not have an expiration date, they are valid forever.
  """

  use Ecto.Schema
  import Ecto.Query

  alias App.Books.Book

  @rand_size 16

  schema "invitation_tokens" do
    field :token, :binary
    belongs_to :book, Book

    timestamps(updated_at: false)
  end

  @doc """
  Builds a token and encode it to be used in the invitation url.

  The encoded token is can be used in urls to be sent to users while the raw part
  is stored in the database.
  """
  def build_invitation_token(book) do
    token = :crypto.strong_rand_bytes(@rand_size)

    {Base.url_encode64(token, padding: false),
     %__MODULE__{
       token: token,
       book_id: book.id
     }}
  end

  @doc """
  Checks if the token is valid and returns its underlying lookup query.

  The query returns the book found by the token, if any.

  The given token is valid if it matches its counterpart in the database.
  """
  def verify_invitation_token_query(token) do
    case Base.url_decode64(token, padding: false) do
      {:ok, decoded_token} ->
        query =
          from token in token_query(decoded_token),
            join: book in assoc(token, :book),
            select: book

        {:ok, query}

      :error ->
        :error
    end
  end

  defp token_query(token) do
    from __MODULE__, where: [token: ^token]
  end

  @doc """
  The query returns the tokens linked to the book.
  """
  def book_tokens_query(book) do
    from __MODULE__, where: [book_id: ^book.id]
  end
end
