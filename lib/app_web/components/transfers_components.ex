defmodule AppWeb.TransfersComponents do
  @moduledoc """
  This module contains all the components specific to transfers.
  """

  use AppWeb, :html

  alias App.Transfers.MoneyTransfer

  @doc """
  Transfer tiles are used to provide a quick glance at a transfer.
  """
  attr :transfer, MoneyTransfer, required: true

  attr :rest, :global

  slot :start,
    doc: """
    By default, an icon is displayed at the start of the tile to represent the transfer
    type. This icon can be overriden by using the `start` slot.
    """

  def transfer_tile(assigns) do
    ~H"""
    <div class={transfer_tile_classes(@transfer)} {@rest}>
      {render_slot(@start, @transfer) || transfer_icon(assigns)}
      <span class="label text-left grow">
        {@transfer.label}
      </span>
      {transfer_amount(assigns)}
    </div>
    """
  end

  @doc """
  Similar to the `transfer_tile/1` component, transfer details provide a quick glance
  at the transfer, but expand when clicked to show more details.

  ## Preloads

  For the component to display correctly, the `:tenant` and `:peers` associations of the
  transfer must be preloaded. For reimbursements, the `:member` of `:peers` is required
  as well.
  """
  attr :transfer, MoneyTransfer, required: true

  attr :rest, :global

  slot :extra

  def transfer_details(assigns) do
    ~H"""
    <details class={[transfer_tile_classes(@transfer), "block h-auto"]} {@rest}>
      <summary class="flex justify-center items-center gap-2">
        {transfer_icon(assigns)}
        <span class="label text-left grow">
          {@transfer.label}
        </span>
        {transfer_amount(assigns)}
        <.icon name={:chevron_down} />
      </summary>
      <.divider />
      {transfer_details_summary(assigns)}
      {render_slot(@extra, @transfer)}
    </details>
    """
  end

  defp transfer_tile_classes(transfer) do
    ["tile pr-4", transfer_color_class(transfer.type)]
  end

  defp transfer_color_class(:payment), do: "tile--red"
  defp transfer_color_class(:income), do: "tile--green"
  defp transfer_color_class(:reimbursement), do: "tile--neutral"

  defp transfer_details_summary(%{transfer: %MoneyTransfer{type: :reimbursement}} = assigns) do
    ~H"""
    <div class="grid grid-cols-2 gap-2 [custom]tile__text">
      <span class="label truncate text-left">
        <.icon name={:credit_card} />
        {@transfer.tenant.nickname}
      </span>
      <span class="label truncate text-right">
        {format_date(@transfer.date)}
        <.icon name={:calendar} />
      </span>
      <span class="label truncate text-left">
        <.icon name={:user} />
        {hd(@transfer.peers).member.nickname}
      </span>
    </div>
    """
  end

  defp transfer_details_summary(assigns) do
    ~H"""
    <div class="grid grid-cols-2 gap-2 [custom]tile__text">
      <span class="label truncate text-left">
        <.icon name={:credit_card} />
        {@transfer.tenant.nickname}
      </span>
      <span class="label truncate text-right">
        {format_date(@transfer.date)}
        <.icon name={:calendar} />
      </span>
      <span class="label truncate text-left">
        <.icon name={:users} />
        {gettext("%{count} members", count: Enum.count(@transfer.peers))}
      </span>
      <span class="label truncate text-right">
        {format_balance_params_code(@transfer.balance_means)}
        <.icon name={:arrows_right_left} />
      </span>
    </div>
    """
  end

  defp format_balance_params_code(:divide_equally), do: gettext("Divided")
  defp format_balance_params_code(:weight_by_revenues), do: gettext("Weighted")

  @doc """
  Transfer icons are based on the transfer type.

  They may be used in the transfer tile to visually represent the type of transfer.
  """
  def transfer_icon(assigns) do
    ~H"<.icon name={transfer_icon_name(@transfer.type)} />"
  end

  def transfer_icon_name(:payment), do: :minus
  def transfer_icon_name(:income), do: :plus
  def transfer_icon_name(:reimbursement), do: :arrow_right

  attr :transfer, MoneyTransfer, required: true

  defp transfer_amount(assigns) do
    assigns = assign(assigns, :sign, transfer_sign(assigns.transfer.type))

    ~H|<span class="label">{@sign <> Money.to_string!(@transfer.amount)}</span>|
  end

  defp transfer_sign(:payment), do: "-"
  defp transfer_sign(:income), do: "+"
  defp transfer_sign(:reimbursement), do: ""
end
