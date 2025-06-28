defmodule App.Books do
  @moduledoc """
  The Book context. Create, update, delete, and find books.
  """

  import Ecto.Query

  alias App.Accounts.User
  alias App.Books.Book
  alias App.Books.BookMember
  alias App.Books.InvitationToken
  alias App.Books.Members
  alias App.Repo

  ## Database getters

  @doc """
  Gets a single book.

  Raises `Ecto.NoResultsError` if the book does not exist.
  """
  @spec get_book!(Book.id()) :: Book.t()
  def get_book!(id), do: Repo.get!(Book, id)

  @doc """
  Gets a single book if it belongs to the user.

  Returns `nil` if the book does not exist or does not belong to the user.
  """
  @spec get_book_of_user(Book.id(), User.t()) :: Book.t() | nil
  def get_book_of_user(id, %User{} = user) do
    books_of_user_query(user)
    |> Repo.get(id)
  end

  @doc """
  Gets a single book if it belongs to the user.

  Raises `Ecto.NoResultsError` if the book does not exist or does not belong to the user.
  """
  @spec get_book_of_user!(Book.id(), User.t()) :: Book.t() | nil
  def get_book_of_user!(id, %User{} = user) do
    books_of_user_query(user)
    |> Repo.get!(id)
  end

  @doc """
  Get all books a specific user belongs to.

  The result may be filtered by passing a map of filters.

  ## Filters

  - `:sort_by` - the field to sort by, one of :alphabetically or :last_created
  - `:owned_by` - the ownership of the book, one of :anyone, :me or :others
  - `:close_state` - the close state of the book, one of :any, :open or :closed
  """
  @spec list_books_of_user(User.t(), map()) :: [Book.t()]
  def list_books_of_user(%User{} = user, filters \\ %{}) do
    books_of_user_query(user)
    |> filter_books_query(filters)
    |> Repo.all()
  end

  # Returns a query that fetches all books a user belongs to.
  @spec books_of_user_query(User.t()) :: Ecto.Query.t()
  defp books_of_user_query(%User{} = user) do
    from [book: book] in Book.base_query(),
      join: member in BookMember,
      as: :current_member,
      on: member.book_id == book.id,
      where: member.user_id == ^user.id
  end

  ## Filters

  @filters_default %{
    sort_by: :last_created,
    owned_by: [],
    close_state: []
  }
  @filters_types %{
    sort_by:
      Ecto.ParameterizedType.init(Ecto.Enum,
        values: [:last_created, :first_created, :alphabetically]
      ),
    owned_by: {:array, Ecto.ParameterizedType.init(Ecto.Enum, values: [:me, :others])},
    close_state: {:array, Ecto.ParameterizedType.init(Ecto.Enum, values: [:open, :closed])}
  }

  defp filter_books_query(query, raw_filters) do
    filters =
      {@filters_default, @filters_types}
      |> Ecto.Changeset.cast(raw_filters, Map.keys(@filters_types))
      |> Ecto.Changeset.apply_changes()

    query
    |> sort_books_by(filters[:sort_by])
    |> filter_books_by_ownership(filters[:owned_by])
    |> filter_books_by_close_state(filters[:close_state])
  end

  # `:sort_by`
  defp sort_books_by(query, :last_created),
    do: from([book: book] in query, order_by: [desc: book.inserted_at])

  defp sort_books_by(query, :first_created),
    do: from([book: book] in query, order_by: [asc: book.inserted_at])

  defp sort_books_by(query, :alphabetically),
    do: from([book: book] in query, order_by: [asc: book.name])

  # filter `:owned_by`
  defp filter_books_by_ownership(query, [:me]),
    do: from([current_member: current_member] in query, where: current_member.role == :creator)

  defp filter_books_by_ownership(query, [:others]),
    do: from([current_member: current_member] in query, where: current_member.role != :creator)

  defp filter_books_by_ownership(query, _empty_or_both), do: query

  # filter `:close_state`

  defp filter_books_by_close_state(query, [:open]),
    do: from([book: book] in query, where: is_nil(book.closed_at))

  defp filter_books_by_close_state(query, [:closed]),
    do: from([book: book] in query, where: not is_nil(book.closed_at))

  defp filter_books_by_close_state(query, _empty_or_both), do: query

  ## Creation

  @doc """
  Creates a book.
  """
  @spec create_book(map(), User.t()) ::
          {:ok, Book.t()}
          | {:error, Ecto.Changeset.t(Book.t())}
          | {:error, Ecto.Changeset.t(BookMember.t())}
  def create_book(attrs, %User{} = creator) do
    result =
      Ecto.Multi.new()
      |> Ecto.Multi.insert(:book, Book.name_changeset(%Book{}, attrs))
      |> Ecto.Multi.insert(:creator, fn %{book: book} ->
        member = %BookMember{
          role: :creator,
          book_id: book.id,
          user_id: creator.id
        }

        Members.change_book_member_nickname(member, attrs)
      end)
      |> Repo.transact()

    case result do
      {:ok, %{book: book}} -> {:ok, book}
      {:error, :book, changeset, _changes} -> {:error, changeset}
      {:error, :creator, changeset, _changes} -> {:error, changeset}
    end
  end

  ## Name update

  @doc """
  Updates a book.
  """
  @spec update_book_name(Book.t(), map()) :: {:ok, Book.t()} | {:error, Ecto.Changeset.t()}
  def update_book_name(book, attrs) do
    book
    |> Book.name_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking book changes.
  """
  @spec change_book_name(Book.t(), map()) :: Ecto.Changeset.t()
  def change_book_name(%Book{} = book, attrs \\ %{}) do
    Book.name_changeset(book, attrs)
  end

  ## Deletion

  @doc """
  Deletes a book.
  """
  @spec delete_book!(Book.t()) :: Book.t()
  def delete_book!(%Book{} = book) do
    book
    |> Book.delete_changeset()
    |> Repo.update!()
  end

  ## Close / Reopen

  @doc """
  Closes a book.
  """
  @spec close_book!(Book.t()) :: Book.t()
  def close_book!(%{closed_at: nil} = book) do
    book
    |> Book.close_changeset()
    |> Repo.update!()
  end

  @doc """
  Re-opens a book after it has been closed.
  """
  @spec reopen_book!(Book.t()) :: Book.t()
  def reopen_book!(%{closed_at: closed_at} = book) when closed_at != nil do
    book
    |> Book.reopen_changeset()
    |> Repo.update!()
  end

  @doc """
  Checks if a book is closed.
  """
  @spec closed?(Book.t()) :: boolean()
  def closed?(book) do
    book.closed_at != nil
  end

  ## Invitations

  @doc """
  Get the invitation token of the book, that shall be used to invite users to the book.
  """
  @spec get_book_invitation_token(Book.t()) :: String.t()
  def get_book_invitation_token(book) do
    get_book_token(book) || insert_book_token(book)
  end

  defp get_book_token(book) do
    invitation_token =
      book
      |> InvitationToken.book_tokens_query()
      |> Repo.one()

    invitation_token && Base.url_encode64(invitation_token.token, padding: false)
  end

  defp insert_book_token(book) do
    {encoded_token, invitation_token} = InvitationToken.build_invitation_token(book)
    Repo.insert!(invitation_token)
    encoded_token
  end

  @doc """
  Get the book linked to an invitation token. Returns `nil` if the token is invalid,
  not found, or expired.
  """
  @spec get_book_by_invitation_token(String.t()) :: Book.t() | nil
  def get_book_by_invitation_token(invitation_token) do
    case InvitationToken.verify_invitation_token_query(invitation_token) do
      {:ok, query} -> Repo.one(query)
      :error -> nil
    end
  end
end
