defmodule App.Books.BookTest do
  use App.DataCase, async: true

  import App.BooksFixtures

  alias App.Books.Book

  describe "name_changeset/2" do
    setup do
      %{book: book_fixture()}
    end

    test "returns a book changeset", %{book: book} do
      assert %Ecto.Changeset{} = Book.name_changeset(book, %{})
    end
  end
end
