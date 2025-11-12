defmodule App.Books.MembersTest do
  use App.DataCase, async: true

  import App.AccountsFixtures
  import App.Books.MembersFixtures
  import App.BooksFixtures

  alias App.Books.Members

  describe "list_members_of_book/1" do
    test "lists all members of a book" do
      book = book_fixture()
      linked_member = book_member_fixture(book, user_id: user_fixture().id)
      unlinked_member = book_member_fixture(book, user_id: nil)
      _other_member = book_member_fixture(book_fixture())

      assert book
             |> Members.list_members_of_book()
             |> Enum.map(& &1.id)
             |> Enum.sort() == [linked_member.id, unlinked_member.id]
    end
  end

  describe "list_unlinked_members_of_book/1" do
    test "lists members of the book that are not linked to a user" do
      book = book_fixture()
      _linked_member = book_member_fixture(book, user_id: user_fixture().id)
      unlinked_member = book_member_fixture(book, user_id: nil)
      _other_member = book_member_fixture(book_fixture())

      assert book
             |> Members.list_unlinked_members_of_book()
             |> Enum.map(& &1.id) == [unlinked_member.id]
    end
  end

  describe "get_member_of_book!/2" do
    setup :book_with_creator_context

    test "returns the member of a book with given id", %{book: book} do
      other_user = user_fixture()
      book_member = book_member_fixture(book, user_id: other_user.id)

      assert result = Members.get_member_of_book!(book_member.id, book)
      assert result.id == book_member.id
      assert result.book_id == book_member.book_id
      assert result.user_id == book_member.user_id
    end

    test "raises if the member does not belong to the book", %{book: book} do
      other_book = book_fixture()
      book_member = book_member_fixture(other_book)

      assert_raise Ecto.NoResultsError, fn ->
        Members.get_member_of_book!(book_member.id, book)
      end
    end

    test "raises if the member does not exist" do
      assert_raise Ecto.NoResultsError, fn ->
        Members.get_member_of_book!(-1, book_fixture())
      end
    end
  end

  describe "create_book_member/2" do
    setup do
      %{book: book_fixture()}
    end

    test "create a new book member", %{book: book} do
      assert {:ok, _book_member} = Members.create_book_member(book, %{nickname: "Member"})
    end

    test "cannot set the user_id", %{book: book} do
      assert {:ok, book_member} =
               Members.create_book_member(book, %{nickname: "Member", user_id: 1})

      assert book_member.user_id == nil
    end

    test "returns an error if given invalid attributes", %{book: book} do
      assert {:error, changeset} =
               Members.create_book_member(book, book_member_attributes(nickname: ""))

      assert errors_on(changeset) == %{nickname: ["can't be blank"]}
    end
  end

  describe "update_book_member_nickname/2" do
    setup do
      book = book_fixture()
      book_member = book_member_fixture(book)

      %{book: book, book_member: book_member}
    end

    test "updates the book member", %{book_member: book_member} do
      assert {:ok, book_member} =
               Members.update_book_member_nickname(book_member, %{nickname: "New Nickname"})

      assert book_member.nickname == "New Nickname"
    end

    test "fails if given invalid values", %{book_member: book_member} do
      assert {:error, changeset} =
               Members.update_book_member_nickname(book_member, %{nickname: ""})

      assert errors_on(changeset) == %{nickname: ["can't be blank"]}
    end

    test "cannot set the user_id", %{book_member: book_member} do
      assert {:ok, book_member} = Members.update_book_member_nickname(book_member, %{user_id: 1})
      assert book_member.user_id == nil
    end
  end

  describe "create_book_member_for_user/3" do
    setup do
      %{book: book_fixture(), user: user_fixture()}
    end

    test "creates a book member with the user", %{book: book, user: user} do
      assert {:ok, book_member} =
               Members.create_book_member_for_user(book, user, %{nickname: "Member"})

      assert book_member.book_id == book.id
      assert book_member.role == :member
      assert book_member.user_id == user.id
      assert book_member.nickname == "Member"
    end

    test "returns an error if the parameters are invalid", %{book: book, user: user} do
      assert {:error, changeset} =
               Members.create_book_member_for_user(book, user, %{nickname: ""})

      assert errors_on(changeset) == %{nickname: ["can't be blank"]}
    end
  end

  describe "link_book_member_to_user/2" do
    setup do
      book = book_fixture()
      book_member = book_member_fixture(book)

      %{book: book, book_member: book_member, user: user_fixture()}
    end

    test "links the book member to the user", %{book_member: book_member, user: user} do
      :ok = Members.link_book_member_to_user(book_member, user)

      book_member = Repo.reload(book_member)
      assert book_member.user_id == user.id
    end
  end

  defp book_with_creator_context(_context) do
    book = book_fixture()
    user = user_fixture()
    member = book_member_fixture(book, user_id: user.id, role: :creator)

    %{
      book: book,
      user: user,
      member: member
    }
  end
end
