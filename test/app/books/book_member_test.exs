defmodule App.Books.BookMemberTest do
  use App.DataCase, async: true

  import App.Books.MembersFixtures
  import App.BooksFixtures

  alias App.Books.BookMember

  describe "nickname_changeset/2" do
    setup do
      book = book_fixture()
      book_member = book_member_fixture(book)

      %{book: book, book_member: book_member}
    end

    test "returns a changeset for the given book member", %{book_member: book_member} do
      assert changeset = BookMember.nickname_changeset(book_member, %{})
      assert changeset.valid?
      assert changeset.params == %{}
    end

    test "validates the user attributes", %{book_member: book_member} do
      assert changeset = BookMember.nickname_changeset(book_member, %{nickname: ""})
      assert errors_on(changeset) == %{nickname: ["can't be blank"]}
    end

    test "cannot set the user_id", %{book_member: book_member} do
      assert changeset = BookMember.nickname_changeset(book_member, %{user_id: 1})
      assert changeset.valid?
      refute Ecto.Changeset.changed?(changeset, :user_id)
    end
  end
end
