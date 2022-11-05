defmodule AppWeb.MoneyTransferLive.Index do
  @moduledoc """
  The money transfer index live view.
  Shows money transfers for the current book.
  """

  use AppWeb, :live_view

  alias App.Books
  alias App.Transfers

  @impl Phoenix.LiveView
  def mount(%{"book_id" => book_id}, _session, socket) do
    book = Books.get_book_of_user!(book_id, socket.assigns.current_user)

    money_transfers =
      book_id
      |> Transfers.list_transfers_of_book()
      |> Transfers.with_tenant()

    socket =
      assign(socket,
        page_title: gettext("Transfers · %{book_name}", book_name: book.name),
        layout_heading: gettext("Transfers"),
        book: book,
        money_transfers: money_transfers
      )

    {:ok, socket, layout: {AppWeb.LayoutView, "book.html"}}
  end

  @impl Phoenix.LiveView
  def handle_event("delete", %{"id" => money_transfer_id}, socket) do
    %{book: book, current_user: current_user} = socket.assigns

    money_transfer = Transfers.get_money_transfer_of_book!(money_transfer_id, book.id)

    {:ok, _} = Transfers.delete_money_transfer(money_transfer, current_user)

    {:noreply,
     update(socket, :money_transfers, fn money_transfers ->
       Enum.reject(money_transfers, &(&1.id == money_transfer.id))
     end)}
  end

  defp class_for_transfer_type(:payment), do: "text-error"
  defp class_for_transfer_type(:income), do: "text-success"
  defp class_for_transfer_type(:reimbursement), do: nil

  defp icon_for_transfer_type(:payment), do: "minus"
  defp icon_for_transfer_type(:income), do: "plus"
  defp icon_for_transfer_type(:reimbursement), do: "arrow-right"

  defp tenant_label_for_transfer_type(:payment, name), do: gettext("Paid by %{name}", name: name)

  defp tenant_label_for_transfer_type(:income, name),
    do: gettext("Received by %{name}", name: name)

  defp tenant_label_for_transfer_type(:reimbursement, name),
    do: gettext("Reimbursed to %{name}", name: name)

  defp format_code(:divide_equally), do: gettext("Divide equally")
  defp format_code(:weight_by_income), do: gettext("Weight by income")
end
