defmodule AppWeb.AccountsComponents do
  @moduledoc """
  A module defining components related to user accounts.
  """

  use AppWeb, :html

  alias App.Accounts.Avatars
  alias App.Accounts.User
  alias App.Books.BookMember

  @doc """
  A component to display a user's avatar in a hero layout.

  The component displays the user's avatar and email address in a hero layout.
  It may also display a member's nickname if `:book_member` is given.
  """
  attr :user, User, required: true
  attr :alt, :string, required: true, doc: "The alt text for the avatar"

  attr :book_member, BookMember, default: nil

  def hero_avatar(assigns) do
    ~H"""
    <div class="text-center my-4">
      <.avatar src={Avatars.avatar_url(@user)} alt={@alt} size={:hero} class="mx-auto" />
      <span :if={@book_member} class="label">{@book_member.nickname}</span>
      <address class="not-italic">{@user.email}</address>
    </div>
    """
  end
end
