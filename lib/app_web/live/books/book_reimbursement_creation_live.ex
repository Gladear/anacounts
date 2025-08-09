defmodule AppWeb.BookReimbursementCreationLive do
  use AppWeb, :live_view

  alias App.Books.Members
  alias App.Transfers
  alias App.Transfers.MoneyTransfer

  on_mount {AppWeb.BookAccess, :ensure_book!}

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.app_page>
      <:breadcrumb>
        <.breadcrumb_ellipsis />
        <.breadcrumb_item navigate={~p"/books/#{@book}/balance"}>
          {gettext("Balance")}
        </.breadcrumb_item>
        <.breadcrumb_item>
          {@page_title}
        </.breadcrumb_item>
      </:breadcrumb>
      <:title>{@page_title}</:title>

      <.form for={@form} phx-change="validate" phx-submit="submit" class="container">
        <section class="grid grid-cols-2 gap-y-2 gap-x-4 mb-4">
          <div class="col-span-2">
            <.input field={@form[:label]} type="text" label={gettext("Label")} required />
          </div>

          <.input
            field={@form[:tenant_id]}
            type="select"
            options={@member_options}
            label={gettext("Received by")}
            required
          />
          <.input field={@form[:amount]} type="money" label={gettext("Amount")} required />

          <.input
            field={@form[:peer_member_id]}
            type="select"
            options={@member_options}
            label={gettext("Paid by")}
            required
          />
          <.input field={@form[:date]} type="date" label={gettext("Date")} required />
        </section>

        <.button_group>
          <.button kind={:primary} type="submit">
            {gettext("Create reimbursement")}
          </.button>
        </.button_group>
      </.form>
    </.app_page>
    """
  end

  @impl Phoenix.LiveView
  def mount(params, _session, socket) do
    book = socket.assigns.book

    members = Members.list_members_of_book(book)
    form = parse_params_form(params, members)

    socket =
      assign(socket,
        page_title: gettext("Manual reimbursement"),
        form: form,
        member_options: Enum.map(members, &{&1.nickname, &1.id})
      )

    {:ok, socket}
  end

  defp parse_params_form(params, members) do
    peer_member = get_params_member(params, members, "from")
    tenant = get_params_member(params, members, "to")
    amount = get_params_amount(params)

    to_form(
      %{
        "label" => tenant && peer_member && new_transfer_label(tenant, peer_member),
        "peer_member_id" => peer_member && peer_member.id,
        "tenant_id" => tenant && tenant.id,
        "amount" => amount,
        "date" => Date.utc_today()
      },
      as: "reimbursement"
    )
  end

  defp get_params_member(params, members, key) do
    if raw_id = Map.get(params, key) do
      id = String.to_integer(raw_id)
      Enum.find(members, &(&1.id == id))
    end
  end

  defp get_params_amount(%{"amount" => amount} = _params) do
    Money.parse(amount)
  end

  defp get_params_amount(_params), do: Money.new!(:EUR, 0)

  defp new_transfer_label(tenant, peer_member) do
    gettext("Reimbursement from %{debtor_name} to %{creditor_name}",
      debtor_name: peer_member.nickname,
      creditor_name: tenant.nickname
    )
  end

  @impl Phoenix.LiveView
  def handle_event("validate", %{"reimbursement" => reimbursement_params}, socket) do
    transfer_params = to_transfer_params(reimbursement_params)

    form =
      %MoneyTransfer{}
      |> Transfers.change_reimbursement(transfer_params)
      |> Map.put(:action, :validate)
      |> to_reimbursement_form()

    {:noreply, assign(socket, :form, form)}
  end

  def handle_event("submit", %{"reimbursement" => reimbursement_params}, socket) do
    book = socket.assigns.book
    transfer_params = to_transfer_params(reimbursement_params)

    case Transfers.create_reimbursement(book, transfer_params) do
      {:ok, _money_transfer} ->
        {:noreply, push_navigate(socket, to: ~p"/books/#{book}/balance")}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_reimbursement_form(changeset))}
    end
  end

  defp to_transfer_params(params) do
    %{
      label: params["label"],
      amount: parse_money_or_nil(params["amount"]),
      date: params["date"],
      tenant_id: params["tenant_id"],
      peers: [%{member_id: params["peer_member_id"]}]
    }
  end

  defp parse_money_or_nil(""), do: nil
  defp parse_money_or_nil(amount), do: Money.new!(:EUR, amount)

  defp to_reimbursement_form(changeset) do
    changeset
    |> to_form(as: "reimbursement")
    |> Map.update!(:params, fn params ->
      {[peer], params} = Map.pop(params, "peers")
      Map.put(params, "peer_member_id", peer.member_id)
    end)
  end
end
