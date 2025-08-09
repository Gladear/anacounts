defmodule AppWeb.BookInvitationControllerTest do
  use AppWeb.ConnCase, async: true

  import App.BooksFixtures
  import App.Books.MembersFixtures

  alias App.Repo

  alias App.Books.BookMember

  setup :register_and_log_in_user

  setup do
    book = book_fixture()
    {encoded_token, _invitation_token} = invitation_token_fixture(book)

    %{book: book, encoded_token: encoded_token}
  end

  describe "GET /invitations/:token" do
    test "prompts the user to join the book", %{
      conn: conn,
      book: book,
      encoded_token: encoded_token
    } do
      book_member = book_member_fixture(book)

      conn = get(conn, ~p"/invitations/#{encoded_token}")

      assert response = html_response(conn, 200)
      assert response =~ "Hello 👋 You have been invited to join a new book:"
      assert response =~ book.name

      # Member list
      assert response =~ book_member.nickname
      assert response =~ "Join"
      assert response =~ "Someone new"

      assert response =~ "Disconnect"
    end

    test "redirects to the home page if the invitation is invalid", %{conn: conn} do
      conn = get(conn, ~p"/invitations/invalid-token")

      assert redirected_to(conn) == ~p"/books"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) ==
               "Invitation link is invalid or it has expired"
    end

    test "redirects to the book if the current user is already part of it", %{
      conn: conn,
      book: book,
      encoded_token: encoded_token,
      user: user
    } do
      _book_member = book_member_fixture(book, user_id: user.id)

      conn = get(conn, ~p"/invitations/#{encoded_token}")

      assert redirected_to(conn) == ~p"/books/#{book}"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) == "You are already part of this book."
    end
  end

  describe "GET /invitations/:token/members/new" do
    test "prompts the new member nickname", %{
      conn: conn,
      book: book,
      encoded_token: encoded_token
    } do
      conn = get(conn, ~p"/invitations/#{encoded_token}/members/new")

      assert response = html_response(conn, 200)
      assert response =~ "Join book"
      assert response =~ book.name
      assert response =~ "Nickname"
      assert response =~ "<input"
    end
  end

  describe "POST /invitations/:token/members/new" do
    test "creates the new member", %{
      conn: conn,
      book: book,
      encoded_token: encoded_token,
      user: user
    } do
      conn =
        post(conn, ~p"/invitations/#{encoded_token}/members/new", %{
          book_member: %{
            nickname: "New Member"
          }
        })

      assert redirected_to(conn) == ~p"/books/#{book}"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "You have been added to the book"

      book_member = Repo.get_by!(BookMember, book_id: book.id, user_id: user.id)
      assert book_member.role == :member
      assert book_member.nickname == "New Member"
    end

    test "re-renders the page if the sent data is invalid", %{
      conn: conn,
      encoded_token: encoded_token
    } do
      conn =
        post(conn, ~p"/invitations/#{encoded_token}/members/new", %{
          book_member: %{
            nickname: ""
          }
        })

      assert response = html_response(conn, 200)
      assert response =~ "can&#39;t be blank"
    end
  end

  describe "GET /invitations/:token/members/:member_id" do
    test "makes the user confirm the member they join as", %{
      conn: conn,
      book: book,
      encoded_token: encoded_token
    } do
      book_member = book_member_fixture(book)

      conn = get(conn, ~p"/invitations/#{encoded_token}/members/#{book_member}")

      assert response = html_response(conn, 200)
      assert response =~ "Join book"
      assert response =~ book.name
      assert response =~ book_member.nickname
    end
  end

  describe "PUT /invitations/:token/members/:member_id" do
    test "join as an existing unlinked member", %{
      conn: conn,
      book: book,
      encoded_token: encoded_token,
      user: user
    } do
      book_member = book_member_fixture(book)

      conn = put(conn, ~p"/invitations/#{encoded_token}/members/#{book_member}")

      assert redirected_to(conn) == ~p"/books/#{book}"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "You have been added to the book"

      book_member = Repo.reload(book_member)
      assert book_member.user_id == user.id
    end
  end
end
