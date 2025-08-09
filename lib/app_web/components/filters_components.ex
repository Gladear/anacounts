defmodule AppWeb.FiltersComponents do
  @moduledoc """
  A collection of components and functions to render filters.

  The main component is `filters/1`. It can be used in conjunction with the
  other functions to create a list of filters.
  """

  use AppWeb, :html

  defstruct [
    :name,
    :icon,
    :label,
    :multiple,
    :options,
    :default
  ]

  @doc """
  Renders a list of filters.

  `phx-change` is triggered an event when one of the filters changes.

  ## TODO

  - display a badge with the number of active filters
  """
  attr :id, :string, required: true, doc: "the id of the filters container"

  attr :filters, :list,
    required: true,
    doc: """
    A list of filters to display. The filters are defined using the other functions
    of this module, `multi_select/1` and `sort_by/1`.
    """

  attr :rest, :global

  def filters(assigns) do
    ~H"""
    <form
      class="flex gap-4 my-4 overflow-auto"
      id={@id}
      {@rest}
      phx-mounted={JS.dispatch("filters:mounted")}
    >
      <.dropdown
        :for={filter <- @filters}
        id={[@id, "_", filter.name]}
        class="js-filters-filter"
        data-name={filter.name}
        data-multiple={filter.multiple}
        data-default={JSON.encode!(filter.default)}
      >
        <:trigger :let={attrs}>
          <.button kind={:secondary} size={:sm} type="button" {attrs}>
            <.icon :if={icon = filter.icon} name={icon} />
            {filter.label}
            <.icon name={:chevron_down} />
          </.button>
        </:trigger>

        <.filter_options
          name={filter.name}
          multiple={filter.multiple}
          options={filter.options}
          default={filter.default}
        />
      </.dropdown>
      <.button kind={:ghost} size={:sm} type="button" class="js-filters-reset">
        {pgettext("Filters", "Reset")}
      </.button>
    </form>
    """
  end

  defp filter_options(%{multiple: true} = assigns) do
    ~H"""
    <.list>
      <.list_item :for={{value, label} <- @options}>
        <label class="form-control-container justify-between">
          <span class="label">{label}</span>
          <.checkbox name={[@name, "[]"]} value={value} checked={value in @default} phx-debounce />
        </label>
      </.list_item>
    </.list>
    """
  end

  defp filter_options(assigns) do
    ~H"""
    <.list>
      <.list_item :for={{value, label} <- @options}>
        <label class="form-control-container justify-between">
          <span class="label">{label}</span>
          <.radio name={@name} value={value} checked={value == @default} phx-debounce />
        </label>
      </.list_item>
    </.list>
    """
  end

  @doc """
  Create a multi-select filter.

  Multiple options can be selected at the same time. The given name will be suffixed
  with `[]` so Phoenix parses the values as a list of strings.

  ## Options

  - `:name` (required) - the name of the checkbox inputs
  - `:label` (required) - the label of the filter
  - `:options` (required) - a list of options to display, in
    the format of a keyword list `[value: label]`.
  - `:default` - the default value of the filter. Must be a list of atoms. Defaults to `[]`.
  - `:icon` - an icon to display next to the label. Defaults to `nil`.
  """
  def multi_select(opts) do
    attrs =
      opts
      |> Keyword.validate!([:name, :label, :options, default: [], icon: nil])
      |> Keyword.merge(multiple: true)

    struct!(__MODULE__, attrs)
  end

  @doc """
  A sort filter. Usually the last of a list of filters.

  The sort filter is a select type filter, with name `sort_by`, label `Sort by` and
  a predefined icon.

  ## Options

  - `:options` (required) - a list of options to display, in the format of a keyword list
    `[value: label]`.
  - `:default` - the default value of the filter. Must be an atom. Defaults to `nil`.
  """
  def sort_by(opts) do
    attrs =
      opts
      |> Keyword.validate!([:options, :default])
      |> Keyword.merge(
        name: "sort_by",
        icon: :arrow_down,
        label: gettext("Sort by"),
        multiple: false
      )

    struct!(__MODULE__, attrs)
  end
end
