defmodule AppWeb.BookCreationLive do
  use AppWeb, :live_view

  alias App.Books
  alias App.Books.Book
  alias App.Books.BookMember

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.app_page>
      <:breadcrumb>
        <.breadcrumb_item>
          {@page_title}
        </.breadcrumb_item>
      </:breadcrumb>
      <:title>{@page_title}</:title>

      <.form for={@form} phx-change="validate" phx-submit="submit" class="container space-y-4">
        <p>{gettext("What do you want to call your new book?")}</p>

        <.input
          field={@form[:name]}
          type="text"
          label={gettext("Name")}
          helper={gettext("Describe the purpose of the book in a few words.")}
          pattern=".{1,255}"
          required
          phx-debounce
        />

        <p>
          {gettext(
            "As the creator, you will be the first member of the book," <>
              " and will be in charge of inviting the first other members."
          )}<br />
          {gettext("As every member, you need a nickname. What do you want to be called?")}
        </p>

        <.input
          field={@form[:nickname]}
          type="text"
          label={gettext("Nickname")}
          helper={gettext("It can be changed later after the book creation.")}
          pattern=".{1,255}"
          required
          phx-debounce
        />

        <.button_group>
          <.button kind={:primary}>
            {gettext("Create")}
          </.button>
        </.button_group>
      </.form>
    </.app_page>
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    form = to_form(%{"name" => "", "nickname" => ""}, as: :book)

    socket =
      assign(socket,
        page_title: gettext("New book"),
        form: form
      )

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("validate", %{"book" => book_params}, socket) do
    book_changeset = Books.change_book_name(%Book{}, book_params)
    member_changeset = BookMember.nickname_changeset(%BookMember{}, book_params)

    changeset = merge_changesets(book_changeset, member_changeset)

    form =
      changeset
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, form: form)}
  end

  def handle_event("submit", %{"book" => book_params}, socket) do
    case Books.create_book(book_params, socket.assigns.current_user) do
      {:ok, book} ->
        {:noreply, push_navigate(socket, to: ~p"/books/#{book}")}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset, as: :book))}
    end
  end

  defp merge_changesets(changeset1, changeset2) do
    changeset1
    |> Map.update!(:params, &Map.merge(&1, changeset2.params))
    |> Map.update!(:errors, &(&1 ++ changeset2.errors))
  end
end
