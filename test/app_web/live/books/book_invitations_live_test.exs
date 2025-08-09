defmodule AppWeb.BookInvitationsLiveTest do
  use AppWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import App.BooksFixtures
  import App.Books.MembersFixtures

  setup [:register_and_log_in_user, :book_with_member_context]

  test "shows the invitation link of the book", %{conn: conn, book: book} do
    {encoded_token, _} = invitation_token_fixture(book)

    {:ok, live, _html} = live(conn, ~p"/books/#{book}/invite")

    assert live
           |> element("#invitation_url")
           |> render() =~ ~s(value="#{url(~p"/invitations/#{encoded_token}")}")
  end

  # Depends on :register_and_log_in_user
  defp book_with_member_context(%{user: user} = context) do
    book = book_fixture()
    member = book_member_fixture(book, user_id: user.id, role: :creator)

    Map.merge(context, %{
      book: book,
      member: member
    })
  end
end
