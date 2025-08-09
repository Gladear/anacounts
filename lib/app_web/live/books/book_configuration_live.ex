defmodule AppWeb.BookConfigurationLive do
  use AppWeb, :live_view

  alias App.Books

  on_mount {AppWeb.BookAccess, :ensure_book!}

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.app_page>
      <:breadcrumb>
        <.breadcrumb_item navigate={~p"/books/#{@book}"}>
          {@book.name}
        </.breadcrumb_item>
        <.breadcrumb_item>
          {@page_title}
        </.breadcrumb_item>
      </:breadcrumb>
      <:title>{@page_title}</:title>

      <.card_grid>
        <.link navigate={~p"/books/#{@book}/configuration/name"}>
          <.card_button icon={:book_open}>
            {gettext("Change name")}
          </.card_button>
        </.link>
        <%= if Books.closed?(@book) do %>
          <.link phx-click="reopen">
            <.card_button icon={:lock_open}>
              {gettext("Reopen book")}
            </.card_button>
          </.link>
        <% else %>
          <.link
            data-confirm={
              gettext(
                "This will prevent prevent any modification from being made to the book." <>
                  " The book can be reopened later. Are you sure you want to close the book?"
              )
            }
            phx-click="close"
          >
            <.card_button icon={:lock_closed}>
              {gettext("Close book")}
            </.card_button>
          </.link>
        <% end %>
        <.link
          data-confirm={
            gettext("Are you sure you want to delete this book? This operation is irreversible.")
          }
          phx-click="delete"
        >
          <.card_button icon={:trash}>
            {gettext("Delete book")}
          </.card_button>
        </.link>
      </.card_grid>
    </.app_page>
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    socket = assign(socket, page_title: gettext("Configuration"))

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("delete", _params, socket) do
    Books.delete_book!(socket.assigns.book)
    {:noreply, push_navigate(socket, to: ~p"/books")}
  end

  def handle_event("close", _params, socket) do
    book = Books.close_book!(socket.assigns.book)
    {:noreply, assign(socket, :book, book)}
  end

  def handle_event("reopen", _params, socket) do
    book = Books.reopen_book!(socket.assigns.book)
    {:noreply, assign(socket, :book, book)}
  end
end
