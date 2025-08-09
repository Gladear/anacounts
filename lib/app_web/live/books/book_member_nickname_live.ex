defmodule AppWeb.BookMemberNicknameLive do
  use AppWeb, :live_view

  alias App.Books.Book
  alias App.Books.BookMember
  alias App.Books.Members

  on_mount {AppWeb.BookAccess, :ensure_book!}

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.app_page>
      <:breadcrumb>
        {nickname_breadcrumbs(assigns)}
      </:breadcrumb>
      <:title>{@page_title}</:title>

      <.form
        for={@form}
        id="member-nickname-form"
        phx-change="validate"
        phx-submit="submit"
        class="container space-y-2"
      >
        <p>
          {nickname_helper(@live_action)}<br />
          <span class="label">{@book_member.nickname}</span>
        </p>
        <p>{gettext("What would you like to change it to?")}</p>
        <.input field={@form[:nickname]} type="text" required phx-debounce />
        <p>
          {gettext(
            "Only the current book will be affected." <>
              " Nicknames can be changed as many times as you want or need to."
          )}
        </p>

        <.button_group>
          <.button kind={:primary}>
            {gettext("Change nickname")}
          </.button>
        </.button_group>
      </.form>
    </.app_page>
    """
  end

  attr :live_action, :atom, required: true
  attr :book, Book, required: true
  attr :book_member, BookMember, required: true

  defp nickname_breadcrumbs(%{live_action: :profile} = assigns) do
    ~H"""
    <.breadcrumb_ellipsis />
    <.breadcrumb_item navigate={~p"/books/#{@book}/profile"}>
      {gettext("My profile")}
    </.breadcrumb_item>
    <.breadcrumb_item>
      {gettext("Change nickname")}
    </.breadcrumb_item>
    """
  end

  defp nickname_breadcrumbs(%{live_action: :member} = assigns) do
    ~H"""
    <.breadcrumb_ellipsis />
    <.breadcrumb_item navigate={~p"/books/#{@book}/members/#{@book_member}"}>
      {@book_member.nickname}
    </.breadcrumb_item>
    <.breadcrumb_item>
      {gettext("Change nickname")}
    </.breadcrumb_item>
    """
  end

  defp nickname_helper(:profile), do: gettext("This is your current nickname")
  defp nickname_helper(:member), do: gettext("This is the current nickname of the member")

  @impl Phoenix.LiveView
  def mount(params, _session, socket) do
    form =
      %BookMember{}
      |> Members.change_book_member_nickname()
      |> to_form()

    socket =
      socket
      |> assign(
        page_title: gettext("Change nickname"),
        form: form
      )
      |> mount_action(socket.assigns.live_action, params)

    {:ok, socket}
  end

  defp mount_action(socket, :profile, _params) do
    assign(socket, :book_member, socket.assigns.current_member)
  end

  defp mount_action(socket, :member, %{"book_member_id" => book_member_id}) do
    book_member = Members.get_member_of_book!(book_member_id, socket.assigns.book)
    assign(socket, :book_member, book_member)
  end

  @impl Phoenix.LiveView
  def handle_event("validate", %{"book_member" => book_member_params}, socket) do
    form =
      %BookMember{}
      |> Members.change_book_member_nickname(book_member_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, :form, form)}
  end

  def handle_event("submit", %{"book_member" => book_member_params}, socket) do
    socket =
      case Members.update_book_member_nickname(socket.assigns.book_member, book_member_params) do
        {:ok, member} ->
          redirect_path = redirect_path(member, socket.assigns.live_action)
          push_navigate(socket, to: redirect_path)

        {:error, changeset} ->
          assign(socket, :form, to_form(changeset))
      end

    {:noreply, socket}
  end

  defp redirect_path(member, :profile), do: ~p"/books/#{member.book_id}/profile"
  defp redirect_path(member, :member), do: ~p"/books/#{member.book_id}/members/#{member}"
end
