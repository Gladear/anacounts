defmodule AppWeb.BookConfigurationNameLive do
  use AppWeb, :live_view

  alias App.Books
  alias App.Books.Book

  on_mount {AppWeb.BookAccess, :ensure_book!}

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.app_page>
      <:breadcrumb>
        <.breadcrumb_ellipsis />
        <.breadcrumb_item navigate={~p"/books/#{@book}/configuration"}>
          {gettext("Configuration")}
        </.breadcrumb_item>
        <.breadcrumb_item>
          {@page_title}
        </.breadcrumb_item>
      </:breadcrumb>
      <:title>{@page_title}</:title>

      <.form for={@form} phx-change="validate" phx-submit="submit" class="container space-y-2">
        <p>
          {gettext("This is the current name of the book")}<br />
          <span class="label">{@book.name}</span>
        </p>
        <p>{gettext("What would you like to change it to?")}</p>

        <.input
          field={@form[:name]}
          type="text"
          label={gettext("Name")}
          helper={gettext("Describe the purpose of the book in a few words.")}
          pattern=".{1,255}"
          required
          phx-debounce
        />

        <.button_group>
          <.button kind={:primary} type="submit">
            {gettext("Change name")}
          </.button>
        </.button_group>
      </.form>
    </.app_page>
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    form = %Book{} |> Book.name_changeset(%{}) |> to_form()

    socket =
      assign(socket,
        page_title: gettext("Change name"),
        form: form
      )

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("validate", %{"book" => book_params}, socket) do
    form =
      %Book{}
      |> Book.name_changeset(book_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, :form, form)}
  end

  def handle_event("submit", %{"book" => book_params}, socket) do
    case Books.update_book_name(socket.assigns.book, book_params) do
      {:ok, book} ->
        {:noreply, push_navigate(socket, to: ~p"/books/#{book}/configuration")}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end
end
