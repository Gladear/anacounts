defmodule AppWeb.BookMemberRevenuesLive do
  use AppWeb, :live_view

  alias App.Accounts.User
  alias App.Balance.BalanceConfig
  alias App.Balance.BalanceConfigs
  alias App.Books.Book
  alias App.Books.BookMember
  alias App.Books.Members

  on_mount {AppWeb.BookAccess, :ensure_book!}

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.app_page>
      <:breadcrumb>
        {revenues_breadcrumbs(assigns)}
      </:breadcrumb>
      <:title>{@page_title}</:title>

      <.form for={@form} phx-change="validate" phx-submit="submit">
        <section class="container space-y-2 mb-4">
          <p>{revenues_balance_config_paragraph(assigns)}</p>
          <p>{gettext("What would you like to set them to?")}</p>
          <.input
            field={@form[:revenues]}
            type="number"
            label={gettext("Revenues")}
            required
            phx-debounce
          />

          <p>
            {gettext(
              "Revenues are set by book. Choose the most fair way to compute revenues" <>
                " (before or after taxes, including gifts or not) with the other members of" <>
                " the book, and enter it here."
            )}
          </p>
          <p>
            {gettext(
              "If you want to update revenues accross multiple books, you will have go to" <>
                " these books and update the revenues there too."
            )}
          </p>
        </section>

        <.button_group>
          <.button kind={:ghost}>
            {gettext("Continue")}
            <.icon name={:chevron_right} />
          </.button>
        </.button_group>
      </.form>
    </.app_page>
    """
  end

  attr :live_action, :atom, required: true
  attr :book, Book, required: true
  attr :book_member, BookMember, required: true

  defp revenues_breadcrumbs(%{live_action: :profile} = assigns) do
    ~H"""
    <.breadcrumb_ellipsis />
    <.breadcrumb_item navigate={~p"/books/#{@book}/profile"}>
      {gettext("My profile")}
    </.breadcrumb_item>
    <.breadcrumb_item>
      {gettext("Set revenues")}
    </.breadcrumb_item>
    """
  end

  defp revenues_breadcrumbs(%{live_action: :member} = assigns) do
    ~H"""
    <.breadcrumb_ellipsis />
    <.breadcrumb_item navigate={~p"/books/#{@book}/members/#{@book_member}"}>
      {@book_member.nickname}
    </.breadcrumb_item>
    <.breadcrumb_item>
      {gettext("Set revenues")}
    </.breadcrumb_item>
    """
  end

  attr :live_action, :atom, required: true
  attr :current_user, User, required: true
  attr :balance_config, BalanceConfig

  defp revenues_balance_config_paragraph(assigns) do
    %{current_user: current_user, balance_config: balance_config} = assigns

    cond do
      balance_config == nil ->
        ~H|{revenues_helper_unset(@live_action)}|

      balance_config.owner_id == current_user.id ->
        ~H"""
        {revenues_helper_owner(@live_action)}<br />
        <span class="label">{@balance_config.revenues}</span>
        """

      true ->
        ~H|{revenues_helper_forbidden(@live_action)}|
    end
  end

  defp revenues_helper_unset(:profile), do: gettext("You have not set your revenues yet.")
  defp revenues_helper_unset(:member), do: gettext("This member revenues were not set yet.")

  defp revenues_helper_owner(:profile), do: gettext("This is your current revenues")
  defp revenues_helper_owner(:member), do: gettext("This is the current revenues of the member")

  defp revenues_helper_forbidden(:profile) do
    gettext("You cannot see your current revenues because they were set by someone else.")
  end

  defp revenues_helper_forbidden(:member) do
    gettext(
      "You cannot see the current revenues of this member, but you are allowed to change them."
    )
  end

  @impl Phoenix.LiveView
  def mount(params, _session, socket) do
    form =
      %BalanceConfig{}
      |> BalanceConfigs.change_balance_config_revenues()
      |> to_form()

    socket =
      socket
      |> assign(
        page_title: gettext("Set revenues"),
        form: form
      )
      |> mount_action(socket.assigns.live_action, params)

    {:ok, socket}
  end

  defp mount_action(socket, :profile, _params) do
    book_member = socket.assigns.current_member

    socket
    |> assign(:book_member, book_member)
    |> assign_balance_config()
  end

  defp mount_action(socket, :member, %{"book_member_id" => book_member_id}) do
    book = socket.assigns.book
    book_member = Members.get_member_of_book!(book_member_id, book)

    if book_member.user_id == nil do
      socket
      |> assign(:book_member, book_member)
      |> assign_balance_config()
    else
      socket
      |> put_flash(:error, gettext("You are not allowed to set the revenues of this member."))
      |> push_navigate(to: ~p"/books/#{book}/members/#{book_member}")
    end
  end

  defp assign_balance_config(socket) do
    balance_config = BalanceConfigs.get_balance_config_of_member(socket.assigns.book_member)
    assign(socket, :balance_config, balance_config)
  end

  @impl Phoenix.LiveView
  def handle_event("validate", %{"balance_config" => balance_config_params}, socket) do
    form =
      %BalanceConfig{}
      |> BalanceConfigs.change_balance_config_revenues(balance_config_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, :form, form)}
  end

  def handle_event("submit", %{"balance_config" => balance_config_params}, socket) do
    %{book_member: book_member, current_user: current_user, live_action: live_action} =
      socket.assigns

    socket =
      case BalanceConfigs.create_balance_config(book_member, current_user, balance_config_params) do
        {:ok, _balance_config} ->
          redirect_path = redirect_path(book_member, live_action)
          push_navigate(socket, to: redirect_path)

        {:error, changeset} ->
          assign(socket, :form, to_form(changeset))
      end

    {:noreply, socket}
  end

  defp redirect_path(member, :profile),
    do: ~p"/books/#{member.book_id}/profile/revenues/transfers"

  defp redirect_path(member, :member),
    do: ~p"/books/#{member.book_id}/members/#{member}/revenues/transfers"
end
