defmodule AppWeb.BookMemberCreationLive do
  @moduledoc """
  The live view for the book member form.
  Create or edit a book member.
  """
  use AppWeb, :live_view

  alias App.Books.BookMember
  alias App.Books.Members

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

      <.form
        for={@form}
        id="member-form"
        phx-change="validate"
        phx-submit="save"
        class="container space-y-2"
      >
        <p>
          {gettext(
            "Members created manually will appear alongside invited members," <>
              " but are not linked to a user until someone invited through the invitation link" <>
              " claims them."
          )}
        </p>
        <p>
          {gettext(
            "The main difference with invited members is that you can see and edit" <>
              " revenues of unlinked members from their member page."
          )}
        </p>
        <.input
          type="text"
          label={gettext("Nickname")}
          field={@form[:nickname]}
          pattern=".{1,255}"
          required
          phx-debounce
        />

        <.button_group>
          <.button kind={:primary}>
            {gettext("Save")}
          </.button>
        </.button_group>
      </.form>
    </.app_page>
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    socket =
      assign(socket,
        page_title: gettext("Create manually"),
        form:
          %BookMember{}
          |> BookMember.nickname_changeset(%{})
          |> to_form()
      )

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("validate", %{"book_member" => book_member_params}, socket) do
    form =
      %BookMember{}
      |> BookMember.nickname_changeset(book_member_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, :form, form)}
  end

  def handle_event("save", %{"book_member" => book_member_params}, socket) do
    book = socket.assigns.book

    case Members.create_book_member(book, book_member_params) do
      {:ok, _member} ->
        {:noreply, push_navigate(socket, to: ~p"/books/#{book}/members")}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end
end
