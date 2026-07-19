defmodule App.BooksTest do
  use App.DataCase, async: true

  import App.AccountsFixtures
  import App.Books.MembersFixtures
  import App.BooksFixtures
  import App.TransfersFixtures

  alias App.Books
  alias App.Books.Book
  alias App.Books.Members

  ## Database getters

  describe "get_book!/1" do
    test "returns the book" do
      %{id: id} = book_fixture()
      assert %{id: ^id} = Books.get_book!(id)
    end

    test "raises if the book doesn't exist" do
      assert_raise Ecto.NoResultsError, fn ->
        Books.get_book!(0)
      end
    end
  end

  describe "get_book_of_user/2" do
    setup do
      book = book_fixture()
      user = user_fixture()
      _member = book_member_fixture(book, user_id: user.id)
      %{book: book, user: user}
    end

    test "returns the book", %{book: book, user: user} do
      user_book = Books.get_book_of_user(book.id, user)
      assert user_book.id == book.id
    end

    test "returns `nil` if the book doesn't belong to the user", %{book: book} do
      other_user = user_fixture()

      assert Books.get_book_of_user(book.id, other_user) == nil
    end

    test "returns `nil` if the book doesn't exist", %{book: book, user: user} do
      assert Books.get_book_of_user(book.id + 10, user) == nil
    end

    test "returns `nil` if the book was deleted", %{book: book, user: user} do
      Books.delete_book!(book)
      refute Books.get_book_of_user(book.id, user)
    end
  end

  describe "get_book_of_user!/2" do
    setup do
      book = book_fixture()
      user = user_fixture()
      _member = book_member_fixture(book, user_id: user.id)
      %{book: book, user: user}
    end

    test "returns the book", %{book: book, user: user} do
      user_book = Books.get_book_of_user!(book.id, user)
      assert user_book.id == book.id
    end

    test "raises if the book doesn't belong to the user", %{book: book} do
      other_user = user_fixture()

      assert_raise Ecto.NoResultsError, fn ->
        Books.get_book_of_user!(book.id, other_user) == nil
      end
    end

    test "raises if the book doesn't exist", %{book: book, user: user} do
      assert_raise Ecto.NoResultsError, fn ->
        Books.get_book_of_user!(book.id + 10, user) == nil
      end
    end

    test "raises if the book was deleted", %{book: book, user: user} do
      Books.delete_book!(book)

      assert_raise Ecto.NoResultsError, fn ->
        Books.get_book_of_user!(book.id, user)
      end
    end
  end

  describe "list_books_of_user/2" do
    setup do
      %{user: user_fixture()}
    end

    test "returns all user books", %{user: user} do
      book1 = book_fixture()
      _member1 = book_member_fixture(book1, user_id: user.id)
      book2 = book_fixture()
      _member2 = book_member_fixture(book2, user_id: user.id)

      _not_member_of_book = book_fixture()

      assert user
             |> Books.list_books_of_user()
             |> Enum.sort_by(& &1.id)
             |> Enum.map(& &1.id) == [book1.id, book2.id]
    end

    test "sorts by first created", %{user: user} do
      book1 = book_fixture(inserted_at: ~N[2020-01-02 00:00:00Z])
      _member1 = book_member_fixture(book1, user_id: user.id)
      book2 = book_fixture(inserted_at: ~N[2020-01-01 00:00:00Z])
      _member2 = book_member_fixture(book2, user_id: user.id)

      assert user
             |> Books.list_books_of_user(%{sort_by: :first_created})
             |> Enum.map(& &1.id) == [book2.id, book1.id]
    end

    test "sorts by last created", %{user: user} do
      book1 = book_fixture(inserted_at: ~N[2020-01-02 00:00:00Z])
      _member1 = book_member_fixture(book1, user_id: user.id)
      book2 = book_fixture(inserted_at: ~N[2020-01-01 00:00:00Z])
      _member2 = book_member_fixture(book2, user_id: user.id)

      assert user
             |> Books.list_books_of_user(%{sort_by: :last_created})
             |> Enum.map(& &1.id) == [book1.id, book2.id]
    end

    test "sorts alphabetically", %{user: user} do
      book1 = book_fixture(name: "Z")
      _member1 = book_member_fixture(book1, user_id: user.id)
      book2 = book_fixture(name: "A")
      _member2 = book_member_fixture(book2, user_id: user.id)

      assert user
             |> Books.list_books_of_user(%{sort_by: :alphabetically})
             |> Enum.map(& &1.id) == [book2.id, book1.id]
    end

    test "filters closed books", %{user: user} do
      book1 = book_fixture(closed_at: nil)
      _member1 = book_member_fixture(book1, user_id: user.id)
      book2 = book_fixture(closed_at: ~N[2020-01-01 00:00:00Z])
      _member2 = book_member_fixture(book2, user_id: user.id)

      assert user
             |> Books.list_books_of_user(%{close_state: [:closed]})
             |> Enum.map(& &1.id) == [book2.id]
    end

    test "filters open books", %{user: user} do
      book1 = book_fixture(closed_at: nil)
      _member1 = book_member_fixture(book1, user_id: user.id)
      book2 = book_fixture(closed_at: ~N[2020-01-01 00:00:00Z])
      _member2 = book_member_fixture(book2, user_id: user.id)

      assert user
             |> Books.list_books_of_user(%{close_state: [:open]})
             |> Enum.map(& &1.id) == [book1.id]
    end
  end

  ## Creation

  describe "create_book/2" do
    setup do
      %{user: user_fixture()}
    end

    test "creates a new book and sets the user the creator", %{user: user} do
      {:ok, book} =
        book_attributes(nickname: "Creator nickname")
        |> Books.create_book(user)

      assert book.name == "A valid book name !"

      assert member = Members.get_membership(book, user)
      assert member.nickname == "Creator nickname"
    end

    test "returns an error when the name is empty", %{user: user} do
      {:error, changeset} =
        book_attributes(name: nil)
        |> Books.create_book(user)

      assert errors_on(changeset) == %{name: ["can't be blank"]}
    end

    test "returns an error when the nickname is empty", %{user: user} do
      {:error, changeset} =
        book_attributes(nickname: nil)
        |> Books.create_book(user)

      assert errors_on(changeset) == %{nickname: ["can't be blank"]}
    end
  end

  ## Name update

  describe "update_book_name/2" do
    setup do
      %{book: book_fixture()}
    end

    test "updates the name of the book", %{book: book} do
      assert {:ok, updated} =
               Books.update_book_name(book, %{
                 name: "My awesome new never seen name !"
               })

      assert updated.name == "My awesome new never seen name !"
    end

    test "returns error changeset with invalid data", %{book: book} do
      assert {:error, changeset} = Books.update_book_name(book, %{name: nil})

      assert errors_on(changeset) == %{name: ["can't be blank"]}
    end
  end

  ## Deletion

  describe "delete_book!/1" do
    setup do
      %{book: book_fixture()}
    end

    test "deletes the book", %{book: book} do
      deleted = Books.delete_book!(book)
      assert deleted.id == book.id
      assert Repo.reload(book) == nil
    end

    test "deletes book members with no dependent money transfers", %{book: book} do
      member = book_member_fixture(book)

      Books.delete_book!(book)

      assert Repo.reload(member) == nil
    end

    test "deletes money transfers along with their tenant and creator book members",
         %{book: book} do
      tenant = book_member_fixture(book)
      creator = book_member_fixture(book)
      transfer = money_transfer_fixture(book, tenant_id: tenant.id, creator_id: creator.id)

      Books.delete_book!(book)

      assert Repo.reload(transfer) == nil
      assert Repo.reload(tenant) == nil
      assert Repo.reload(creator) == nil
    end

    test "deletes transfer peers along with the peer book member", %{book: book} do
      tenant = book_member_fixture(book)
      peer_member = book_member_fixture(book)
      transfer = money_transfer_fixture(book, tenant_id: tenant.id)
      peer = peer_fixture(transfer, member_id: peer_member.id)

      Books.delete_book!(book)

      assert Repo.reload(peer) == nil
      assert Repo.reload(peer_member) == nil
    end

    test "does not delete data belonging to other books", %{book: book} do
      other_book = book_fixture()
      other_member = book_member_fixture(other_book)
      other_transfer = money_transfer_fixture(other_book, tenant_id: other_member.id)
      other_peer = peer_fixture(other_transfer, member_id: other_member.id)

      Books.delete_book!(book)

      assert Repo.reload(other_member) == other_member
      assert Repo.reload(other_transfer) == other_transfer
      assert Repo.reload(other_peer) == other_peer
    end
  end

  ## Close / Reopen

  describe "close_book!/1" do
    test "closes the book" do
      book = book_fixture(closed_at: nil)

      closed = Books.close_book!(book)
      assert closed.id == book.id

      assert closed_book = Repo.get(Book, book.id)
      assert closed_book.closed_at
    end

    test "crashes if the book is already closed" do
      book = book_fixture(closed_at: ~N[2020-01-01 00:00:00Z])

      assert_raise FunctionClauseError, fn ->
        Books.close_book!(book)
      end
    end
  end

  describe "reopen_book!/1" do
    test "re-opens the book" do
      book = book_fixture(closed_at: ~N[2020-01-01 00:00:00Z])

      reopened = Books.reopen_book!(book)
      assert reopened.id == book.id

      assert reopened_book = Repo.get(Book, book.id)
      refute reopened_book.closed_at
    end

    test "crashes if the book is not closed" do
      book = book_fixture(closed_at: nil)

      assert_raise FunctionClauseError, fn ->
        Books.reopen_book!(book)
      end
    end
  end

  describe "closed?/1" do
    test "returns `false` if the book is not closed" do
      book = book_fixture(closed_at: nil)
      refute Books.closed?(book)
    end

    test "returns `true` if the book is closed" do
      book = book_fixture(closed_at: ~N[2020-01-01 00:00:00Z])
      assert Books.closed?(book)
    end
  end

  ## Invitations

  describe "get_book_invitation_token/1" do
    setup do
      %{book: book_fixture()}
    end

    test "creates the invitation token of a book", %{book: book} do
      assert encoded_token = Books.get_book_invitation_token(book)

      assert found = Books.get_book_by_invitation_token(encoded_token)
      assert found.id == book.id
    end

    test "returns the existing invitation if there is one", %{book: book} do
      {encoded_token, _} = invitation_token_fixture(book)

      assert ^encoded_token = Books.get_book_invitation_token(book)
    end
  end

  describe "get_book_by_invitation_token/1" do
    setup do
      %{book: book_fixture()}
    end

    test "returns the linked book", %{book: book} do
      {encoded_token, _} = invitation_token_fixture(book)

      assert found = Books.get_book_by_invitation_token(encoded_token)
      assert found.id == book.id
    end

    test "returns `nil` if the invitation token doesn't exist" do
      assert Books.get_book_by_invitation_token("foo") == nil
    end
  end
end
