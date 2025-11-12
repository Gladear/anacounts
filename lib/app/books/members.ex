defmodule App.Books.Members do
  @moduledoc """
  The Books.Members context.
  """

  import Ecto.Query
  alias App.Repo

  alias App.Accounts.User
  alias App.Books.Book
  alias App.Books.BookMember

  @doc """
  Gets a single book_member.

  Raises `Ecto.NoResultsError` if the book member does not exist.
  """
  @spec get_book_member!(BookMember.id()) :: BookMember.t()
  def get_book_member!(id) do
    BookMember.base_query()
    |> Repo.get!(id)
  end

  @doc """
  Lists all members of a book.
  """
  @spec list_members_of_book(Book.t()) :: [BookMember.t()]
  def list_members_of_book(book) do
    members_of_book_query(book)
    |> Repo.all()
  end

  @doc """
  Lists all members of a book that are not linked to a user.
  """
  @spec list_unlinked_members_of_book(Book.t()) :: [BookMember.t()]
  def list_unlinked_members_of_book(book) do
    members_of_book_query(book)
    |> where([book_member: book_member], is_nil(book_member.user_id))
    |> Repo.all()
  end

  @doc """
  Get a single member of a book.

  Raises `Ecto.NoResultsError` if the book member does not exist or
  is not a member of the book.
  """
  @spec get_member_of_book!(BookMember.id(), Book.t()) :: BookMember.t()
  def get_member_of_book!(id, book) do
    members_of_book_query(book)
    |> where([book_member: book_member], book_member.id == ^id)
    |> Repo.one!()
  end

  defp members_of_book_query(book) do
    from([book_member: book_member] in BookMember.book_query(book),
      left_join: user in assoc(book_member, :user),
      order_by: [asc: book_member.nickname]
    )
    |> BookMember.select_email()
  end

  @doc """
  Get the book member entity linking a user to a book.

  Returns `nil` if the user is not a member of the book.
  """
  @spec get_membership(Book.t(), User.t()) :: BookMember.t() | nil
  def get_membership(book, user) do
    Repo.get_by(BookMember, book_id: book.id, user_id: user.id)
  end

  @doc """
  Create a new book member within a book.
  """
  @spec create_book_member(Book.t(), map()) ::
          {:ok, BookMember.t()} | {:error, Ecto.Changeset.t()}
  def create_book_member(%Book{} = book, attrs) do
    %BookMember{
      book_id: book.id,
      role: :member
    }
    |> BookMember.nickname_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Update the nickname of a book member.
  """
  @spec update_book_member_nickname(BookMember.t(), map()) ::
          {:ok, BookMember.t()} | {:error, Ecto.Changeset.t()}
  def update_book_member_nickname(book_member, attrs) do
    book_member
    |> BookMember.nickname_changeset(attrs)
    |> Repo.update()
  end

  ## User invitations

  @doc """
  Create a new book member within a book and link it to a user.
  """
  @spec create_book_member_for_user(Book.t(), User.t(), map()) ::
          {:ok, BookMember.t()} | {:error, Ecto.Changeset.t()}
  def create_book_member_for_user(book, user, params) do
    %BookMember{
      book_id: book.id,
      role: :member,
      user_id: user.id
    }
    |> BookMember.nickname_changeset(params)
    |> Repo.insert()
  end

  @doc """
  Link an existing book member to a user.
  """
  @spec link_book_member_to_user(BookMember.t(), User.t()) :: :ok
  def link_book_member_to_user(book_member, user) do
    {1, nil} =
      from(BookMember, where: [id: ^book_member.id])
      |> Repo.update_all(set: [user_id: user.id])

    :ok
  end
end
