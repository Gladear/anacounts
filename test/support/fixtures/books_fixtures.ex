defmodule App.BooksFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `App.Books` context.
  """

  alias App.Repo

  alias App.Books.Book
  alias App.Books.InvitationToken

  def book_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      name: "A valid book name !"
    })
  end

  def book_fixture(attrs \\ %{}) do
    struct!(Book, book_attributes(attrs))
    |> Repo.insert!()
  end

  def invitation_token_fixture(book) do
    {encoded_token, invitation_token} = InvitationToken.build_invitation_token(book)
    {encoded_token, Repo.insert!(invitation_token)}
  end
end
