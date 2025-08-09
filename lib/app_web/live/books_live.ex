defmodule AppWeb.BooksLive do
  @moduledoc """
  The book index live view.
  List all books the user is member of.
  """

  use AppWeb, :live_view

  import AppWeb.FiltersComponents

  alias App.Accounts.Avatars
  alias App.Books

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="app-page">
      <header class="flex justify-between">
        <h1 class="title-1">{@page_title}</h1>
        <.button kind={:ghost} navigate={~p"/users/settings"} class="p-1">
          <.avatar src={Avatars.avatar_url(@current_user)} alt={gettext("My account")} />
        </.button>
      </header>
      <main>
        <.alert_flash flash={@flash} kind={:error} class="mb-4" />

        <.link navigate={~p"/books/new"}>
          <.tile kind={:primary}>
            <.icon name={:plus} />
            {gettext("Create a new book")}
          </.tile>
        </.link>

        <.filters
          id="books-filters"
          phx-change="filters"
          filters={[
            multi_select(
              name: "owned_by",
              label: gettext("Owned by"),
              options: [
                me: gettext("Me"),
                others: gettext("Others")
              ]
            ),
            multi_select(
              name: "close_state",
              label: gettext("State"),
              options: [
                open: gettext("Open"),
                closed: gettext("Closed")
              ],
              default: [:open]
            ),
            sort_by(
              options: [
                last_created: gettext("Last created"),
                first_created: gettext("First created"),
                alphabetically: gettext("Alphabetically")
              ],
              default: :last_created
            )
          ]}
        />

        <div id="books" phx-update="stream">
          <.link :for={{dom_id, book} <- @streams.books} id={dom_id} navigate={~p"/books/#{book.id}"}>
            <.tile class="mt-4">
              <span class="label grow leading-none line-clamp-2">{book.name}</span>
              <.button kind={:ghost}>
                Open <.icon name={:chevron_right} />
              </.button>
            </.tile>
          </.link>
        </div>
      </main>
    </div>
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    books = list_books(socket.assigns.current_user)

    socket =
      socket
      |> assign(:page_title, gettext("My books"))
      |> stream(:books, books)

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("filters", params, socket) do
    books = list_books(socket.assigns.current_user, params)

    {:noreply, stream(socket, :books, books, reset: true)}
  end

  @default_filters %{
    close_state: [:open],
    sort_by: :last_created
  }

  defp list_books(current_user, filters \\ @default_filters) do
    Books.list_books_of_user(current_user, filters)
  end
end
