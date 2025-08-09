defmodule AppWeb.BookInvitationHTML do
  use AppWeb, :html

  alias App.Accounts.User
  alias App.Books.Book

  embed_templates "book_invitation_html/*"

  attr :book, Book, required: true
  attr :current_user, User, required: true

  slot :inner_block, required: true

  defp invitation_layout(assigns) do
    ~H"""
    <div class="text-center">
      <p class="mb-2">{gettext("Hello 👋 You have been invited to join a new book:")}</p>
      <p class="text-xl font-bold line-clamp-2 mb-4">{@book.name}</p>
    </div>

    {render_slot(@inner_block)}

    <div class="text-right mt-4">
      {gettext("Not %{user_name}?", user_name: @current_user.email)}
      <.anchor href={~p"/users/log_out"} method="delete">
        {gettext("Disconnect")}
      </.anchor>
    </div>
    """
  end
end
