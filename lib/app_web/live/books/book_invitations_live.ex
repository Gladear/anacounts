defmodule AppWeb.BookInvitationsLive do
  @moduledoc """
  The invitation live view.
  Provide the invitation link of the book.
  """
  use AppWeb, :live_view

  alias App.Books

  on_mount {AppWeb.BookAccess, :ensure_book!}
  on_mount {AppWeb.BookAccess, :ensure_open_book!}

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.app_page>
      <:breadcrumb>
        <.breadcrumb_ellipsis />
        <.breadcrumb_item navigate={~p"/books/#{@book}/members"}>
          {gettext("Members")}
        </.breadcrumb_item>
        <.breadcrumb_item>
          {@page_title}
        </.breadcrumb_item>
      </:breadcrumb>
      <:title>{@page_title}</:title>

      <div class="container">
        <p class="mb-4">
          {gettext(
            "People clicking this link will be asked either to join as an existing member," <>
              " or to create a new one."
          )}
        </p>

        <.input
          type="text"
          name="invitation_url"
          value={@invitation_url}
          readonly
          phx-click={
            JS.dispatch("app:copy-to-clipboard")
            |> JS.hide(to: "#copy-to-clipboard-helper")
            |> JS.show(to: "#copied-to-clipboard")
          }
        />
        <p id="copy-to-clipboard-helper">
          {gettext("Share this link so people can join your book")}
        </p>
        <p id="copied-to-clipboard" class="hidden">
          {gettext("Copied to clipboard !")}
        </p>
      </div>
    </.app_page>
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    book = socket.assigns.book
    invitation_token = Books.get_book_invitation_token(book)

    socket =
      assign(socket,
        page_title: gettext("Invitations"),
        invitation_url: url(~p"/invitations/#{invitation_token}")
      )

    {:ok, socket}
  end
end
