defmodule AppWeb.CoreComponents do
  @moduledoc """
  Provides core UI components.

  The components defined here are the base building blocks of the application.
  They define and represent the design system of the application.

  Related CSS can be found in `assets/css/components/*`.
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS

  # Some components need to pass attributes down to a <.link> component. The attributes
  # of the <.link> component are sometimes out of scope of the `:global` type, but this
  # can be overriden using the `:include` option of `attr/3`.
  # e.g. `attr :rest, :global, include: @link_attrs`
  @link_attrs ~w(navigate patch href replace method csrf_token download hreflang referrerpolicy rel target type)

  # Attributes of the `<input>` HTML element
  @input_attrs ~w(name value checked step disabled)

  # prepend a class in `[:rest, :class]`
  defp prepend_class(assigns, class) do
    update(assigns, :rest, fn rest -> Map.update(rest, :class, class, &[class, &1]) end)
  end

  ## Alert

  @doc """
  An alert is a message that attracts the user's attention to important information.

  Alerts should be top-level components, placed directly within the body of the page.
  They should take the full width of the screen and should be placed at the beginning
  of the page so that they are visible to the user as soon as the page loads.
  """
  attr :kind, :atom, values: [:info, :warning, :error]

  attr :rest, :global

  slot :inner_block, required: true

  def alert(assigns) do
    assigns = prepend_class(assigns, ["alert", alert_kind_class(assigns.kind)])

    ~H"""
    <div {@rest}>
      {alert_icon(assigns)}
      {render_slot(@inner_block)}
    </div>
    """
  end

  defp alert_kind_class(:info), do: "alert--info"
  defp alert_kind_class(:warning), do: "alert--warning"
  defp alert_kind_class(:error), do: "alert--error"

  defp alert_icon(%{kind: :info} = assigns), do: ~H"<.icon name={:information_circle} />"
  defp alert_icon(%{kind: :warning} = assigns), do: ~H"<.icon name={:exclamation_triangle} />"
  defp alert_icon(%{kind: :error} = assigns), do: ~H"<.icon name={:exclamation_circle} />"

  @doc """
  Alert flashes display `alert/1` components based on flash messages.
  """
  attr :flash, :map, doc: "The @flash assign"
  attr :kind, :atom, values: [:info, :error]

  attr :rest, :global

  def alert_flash(assigns) do
    assigns =
      assign(assigns, :message, Phoenix.Flash.get(assigns.flash, assigns.kind))

    ~H|<.alert :if={@message} kind={@kind} {@rest}>{@message}</.alert>|
  end

  ## Anchor

  @doc """
  An anchor is a stylized link that is used to navigate to a different page.
  """
  attr :rest, :global, include: @link_attrs

  slot :inner_block, required: true

  def anchor(assigns) do
    assigns = prepend_class(assigns, "anchor")

    ~H|<.link {@rest}>{render_slot(@inner_block)}</.link>|
  end

  ## Avatar

  @doc """
  An avatar is a visual representation of a user or entity.

  Avatar must always be accompanied by an `alt` attribute to provide a meaningful
  description of the image for screen readers.
  """

  attr :src, :string, required: true
  attr :alt, :string, required: true
  attr :size, :atom, default: :sm, values: [:sm, :hero]

  attr :rest, :global

  def avatar(assigns) do
    assigns = prepend_class(assigns, ["avatar", avatar_size_class(assigns.size)])

    ~H"""
    <img src={@src} alt={@alt} {@rest} />
    """
  end

  defp avatar_size_class(:sm), do: "avatar--sm"
  defp avatar_size_class(:hero), do: "avatar--hero"

  ## breadcrumb

  @doc """
  Breadcrumbs are a navigation aid that helps users understand where they are in the
  application and allow them to navigate back to a higher level in the hierarchy.

  Breadcrumbs are placed at the top of the page. They should not contain more than
  two items. If there are more than two items, replace the excess by
  the `breadcrumb_ellipsis/1` component.

  This component should be used in conjunction with the `breadcrumb_home/1` and
  `breadcrumb_item/1` components.
  """
  attr :rest, :global

  slot :inner_block, required: true

  def breadcrumb(assigns) do
    assigns = prepend_class(assigns, "breadcrumb")

    ~H"""
    <nav {@rest}>
      {render_slot(@inner_block)}
    </nav>
    """
  end

  @doc """
  The breadcrumb home item is a special breadcrumb item representing the home of the
  navigation hierarchy.

  It should be the first item in the breadcrumb list. Although it is not marked as
  required, the component should always contain any of a `href`, a `navigate`, or a
  `patch` attribute.

  This component should be used within the `breadcrumb/1` component.
  """
  attr :alt, :string, required: true

  attr :rest, :global, include: @link_attrs

  def breadcrumb_home(assigns) do
    ~H"""
    <.link {@rest}>
      <.icon name={:home} alt={@alt} />
    </.link>
    """
  end

  @doc """
  A breadcrumb item is an item representing a step in the navigation hierarchy in a
  breadcrumb component.

  The item component contains the chevron preceding it.

  If it is not the last item of the list, the component should always contain a
  `navigate` attribute linking to the corresponding page.

  This component should be used within the `breadcrumb/1` component.
  """
  attr :navigate, :string

  slot :inner_block, required: true

  def breadcrumb_item(%{navigate: _} = assigns) do
    ~H"""
    <.icon name={:chevron_right} />
    <.link class="breadcrumb__item" navigate={@navigate}>
      {render_slot(@inner_block)}
    </.link>
    """
  end

  def breadcrumb_item(assigns) do
    ~H"""
    <.icon name={:chevron_right} />
    <span class="breadcrumb__item breadcrumb__item--active">
      {render_slot(@inner_block)}
    </span>
    """
  end

  @doc """
  The breadcrumb ellipsis is a special item it used when there are too many items in a
  breadcrumb component.

  It is used as the second item of the list, right after the home item.

  This component should be used within the `breadcrumb/1` component.
  """
  def breadcrumb_ellipsis(assigns) do
    ~H"""
    <.icon name={:chevron_right} />
    <span class="breadcrumb__item breadcrumb__item--ellipsis">…</span>
    """
  end

  ## Button

  @doc """
  Buttons are used to trigger actions or navigate.

  Buttons are rendered as `<button>` elements by default. If the `:navigate` attribute
  is given, the button will be rendered using the `link/1` component of Phoenix.

  ## Kinds

  Buttons have three kinds, `:primary`, `:secondary`, and `:ghost`.

  Primary buttons are sometimes called "Call to action", and are used for the primary
  action in a view. They draw the user's attention and are used to guide the user to a
  significant step, whether it is to submit a form, create a new entry, close a popup,
  etc. There cannot be more than one CTA button on the screen at a time.

  Feature and Ghost buttons are used for secondary actions.
  """

  attr :kind, :atom,
    required: true,
    values: [:primary, :secondary, :ghost]

  attr :size, :atom, default: :md, values: [:sm, :md]

  attr :navigate, :string, doc: "A URL to navigate to when clicking the button"

  attr :rest, :global,
    include:
      @link_attrs ++
        ~w(disabled) ++
        ~w(form formaction formenctype formmethod formnovalidate formtarget) ++
        ~w(popovertarget)

  slot :inner_block, required: true

  def button(%{navigate: _} = assigns) do
    assigns = prepend_button_classes(assigns)

    link(assigns)
  end

  def button(assigns) do
    assigns = prepend_button_classes(assigns)

    ~H"""
    <button {@rest}>
      {render_slot(@inner_block)}
    </button>
    """
  end

  defp prepend_button_classes(assigns) do
    prepend_class(assigns, [
      "button",
      button_kind_class(assigns.kind),
      button_size_class(assigns.size)
    ])
  end

  defp button_kind_class(:primary), do: "button--primary"
  defp button_kind_class(:secondary), do: "button--secondary"
  defp button_kind_class(:ghost), do: "button--ghost"

  defp button_size_class(:sm), do: "button--sm"
  defp button_size_class(:md), do: nil

  @doc """
  Button groups are used to group buttons together.
  """
  attr :rest, :global

  slot :inner_block

  def button_group(assigns) do
    assigns = prepend_class(assigns, "button-group")

    ~H|<div {@rest}>{render_slot(@inner_block)}</div>|
  end

  ## Card

  @doc """
  Cards are simple containers. They consist of white boxes with rounded corners,
  containing a title and a body. In most cases, the body is a simple short text,
  but more complex content can be added.
  """
  attr :color, :atom,
    values: [:secondary, :green, :red, :neutral],
    default: :secondary,
    doc: """
    The color of the card is used when displaying the balance of members, conveying the
    idea of positive, negative, and undefined balances.
    """

  attr :rest, :global

  slot :title, required: true
  slot :inner_block, required: true

  def card(assigns) do
    assigns = prepend_card_classes(assigns)

    ~H"""
    <div {@rest}>
      <div class="card__title">
        {render_slot(@title)}
      </div>
      <div class="card__body">
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  @doc """
  Card buttons are a specialized version of the card component that contains act as
  a button or link and only contain an icon and label.

  Unlike traditional cards, card buttons do not have a title slot since the title is
  the main content of the component.

  Card buttons cannot be used to display balance, so they cannot be green, red, or
  neutral. They can however be primary or secondary. The same usage rules as the button
  component apply.
  """
  attr :icon, :atom
  attr :color, :atom, values: [:primary, :secondary], default: :secondary

  attr :rest, :global

  slot :inner_block, required: true

  def card_button(assigns) do
    # TODO add disabled style, based on parent aria-disabled
    # Selector: [aria-disabled="true"] .card--button { ... }
    assigns = prepend_card_classes(assigns, "card--button")

    ~H"""
    <div {@rest}>
      <.icon name={@icon} />
      {render_slot(@inner_block)}
    </div>
    """
  end

  defp prepend_card_classes(assigns, extra_classes \\ nil) do
    prepend_class(assigns, ["card", card_color_class(assigns.color), extra_classes])
  end

  defp card_color_class(:primary), do: "card--primary"
  defp card_color_class(:secondary), do: "card--secondary"
  defp card_color_class(:green), do: "card--green"
  defp card_color_class(:red), do: "card--red"
  defp card_color_class(:neutral), do: "card--neutral"

  ## Card grid

  @doc """
  Card grid are used to display a collection of cards in a grid layout.

  The grid contains two columns of equal width.
  """
  attr :rest, :global

  slot :inner_block, required: true

  def card_grid(assigns) do
    assigns = prepend_class(assigns, "card-grid")

    ~H"""
    <div {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  ## Checkbox

  @doc """
  Checkboxes are used to let the user choose whether to activate an option when a form
  submission.

  When the effect of the checkbox is immediate, switches should be used instead.
  (NB, no switch component has been developed yet).

  For usage with Phoenix's forms, consider using the `input/1` component.
  """
  attr :rest, :global, include: @input_attrs

  def checkbox(assigns) do
    assigns = prepend_class(assigns, "checkbox")

    ~H"""
    <input type="checkbox" {@rest} />
    """
  end

  ## Divider

  @doc """
  Dividers are used to separate distinct sectionss of content.

  For example, they are used to separate the login form from
  the sign-up button in the login page, or to separate the
  items of a list (although it's implemented in a different way,
  the visual is the same).
  """

  attr :rest, :global

  def divider(assigns) do
    assigns = prepend_class(assigns, "divider")

    ~H"""
    <hr {@rest} />
    """
  end

  @doc """
  Dropdowns are used to display a list of options to the user.

  They only appear when the user clicks on the trigger.
  """
  attr :id, :any, required: true

  attr :rest, :global

  slot :trigger,
    required: true,
    doc: """
    The trigger of the dropdown.

    The trigger is required to have some attributes, which are passed through the `:let`
    attributes.

    ## Example

        <.dropdown id="dropdown">
          <:trigger :let={attrs}>
            <.breadcrumb_ellipsis {attrs} />
          </:trigger>
          ...
        </.dropdown>
    """

  slot :inner_block, required: true

  def dropdown(assigns) do
    assigns = prepend_class(assigns, "dropdown")

    ~H"""
    {render_slot(@trigger, %{
      popovertarget: @id,
      "phx-mounted": JS.dispatch("dropdown:mounted", to: "##{@id}")
    })}
    <div id={@id} popover {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  ## Icon

  @doc """
  Icons may be used in a variety of contexts to provide visual cues and enhance the user
  experience.
  """
  attr :name, :atom, required: true, doc: "The name of the icon"
  attr :alt, :string, default: nil, doc: "The alt text of the icon"
  attr :class, :any, default: nil, doc: "Extra classes to add to the icon"
  attr :rest, :global

  def icon(assigns) do
    ~H"""
    <.heroicon name={@name} aria-label={@alt} class={["icon", @class]} {@rest} />
    """
  end

  # Copied from Github's heroicons_elixir issue #21.
  # https://github.com/mveytsman/heroicons_elixir/issues/21#issuecomment-1288551770
  attr :name, :atom, required: true
  attr :outline, :boolean, default: true
  attr :solid, :boolean, default: false
  attr :mini, :boolean, default: false

  attr :rest, :global,
    doc: "the arbitrary HTML attributes for the svg container",
    include: ~w(fill stroke stroke-width)

  def heroicon(assigns) do
    apply(Heroicons, assigns.name, [assigns])
  end

  ## List

  @doc """
  Lists are used to display a collection of items in a vertical list.
  """
  attr :rest, :global

  slot :inner_block, required: true

  def list(assigns) do
    assigns = prepend_class(assigns, "list")

    ~H"""
    <ul {@rest}>
      {render_slot(@inner_block)}
    </ul>
    """
  end

  @doc """
  List items are used within lists to display items.

  When using buttons within list item, consider using `list_item_link/1` instead.

  This component should be used within the `list/1` component.
  """
  attr :rest, :global

  slot :inner_block, required: true

  def list_item(assigns) do
    assigns = prepend_class(assigns, "list__item")

    ~H"""
    <li {@rest}>
      {render_slot(@inner_block)}
    </li>
    """
  end

  @doc """
  List item links are variants of list items that are used to navigate.

  They should contain a ghost button placed at the end of the item, indicating the intent
  to navigate to a different page.

  This component should be used within the `list/1` component.
  """
  attr :rest, :global, include: @link_attrs

  slot :inner_block, required: true

  def list_item_link(assigns) do
    assigns = prepend_class(assigns, "list__item list__item--link")

    ~H"""
    <.link role="listitem" {@rest}>
      {render_slot(@inner_block)}
    </.link>
    """
  end

  ## Radio input

  @doc """
  Radio inputs are used to let the user choose one option from a list of options.

  For usage with Phoenix's forms, consider using the `input/1` component.
  """
  attr :rest, :global, include: @input_attrs

  def radio(assigns) do
    assigns = prepend_class(assigns, "radio")

    ~H"""
    <input type="radio" {@rest} />
    """
  end

  ## Select

  @doc """
  Selects are form controls used to input data from a list of options.

  For usage with Phoenix's forms, consider using the `input/1` component.
  """

  attr :prompt, :string,
    default: nil,
    doc: "the prompt to display as the first option of the select"

  attr :value, :any, default: nil, doc: "the initially selected value"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"

  attr :error, :boolean, default: false

  attr :container_class, :any, default: nil, doc: "Classes added to the input container"
  attr :rest, :global, include: @input_attrs

  def select(assigns) do
    assigns = prepend_class(assigns, "text-input__input text-input__input--select")

    ~H"""
    <div class={[
      "text-input",
      text_input_error_class(assigns.error),
      @container_class
    ]}>
      <select {@rest}>
        <option :if={@prompt} value="">{@prompt}</option>
        {Phoenix.HTML.Form.options_for_select(@options, @value)}
      </select>
    </div>
    """
  end

  ## Text input

  @doc """
  Text inputs are used to collect data from the user.

  The name `text_input` is used to differentiate from the `input/1` component,
  but the input can actually be used for multiple types of input, listed in the
  `:type` attribute.

  For usage with Phoenix's forms, consider using the `input/1` component.
  """

  attr :type, :string, default: "text", values: ~w(date email number password text)
  attr :error, :boolean, default: false

  attr :prefix, :atom, doc: "An icon to display before the input"
  attr :suffix, :atom, doc: "An icon to display after the input"

  attr :container_class, :any, default: nil, doc: "Classes added to the input container"
  attr :rest, :global, include: @input_attrs

  def text_input(assigns) do
    assigns = prepend_class(assigns, "text-input__input")

    ~H"""
    <div class={["text-input", text_input_error_class(assigns.error), @container_class]}>
      {text_input_prefix(assigns)}
      <input type={@type} {@rest} />
      {text_input_suffix(assigns)}
    </div>
    """
  end

  defp text_input_error_class(true), do: "text-input--error"
  defp text_input_error_class(false), do: nil

  defp text_input_prefix(%{prefix: _} = assigns) do
    ~H|<.icon class="text-input__addon" name={@prefix} />|
  end

  defp text_input_prefix(_assigns), do: nil

  defp text_input_suffix(%{suffix: _} = assigns) do
    ~H|<.icon class="text-input__addon" name={@suffix} />|
  end

  defp text_input_suffix(_assigns), do: nil

  ## Tile

  @doc """
  Tiles are interactive elements that are mostly used to navigate to different pages.
  """
  attr :kind, :atom,
    values: [:primary, :secondary],
    default: :secondary

  attr :rest, :global

  slot :inner_block, required: true

  def tile(assigns) do
    assigns = prepend_class(assigns, ["tile", tile_kind_class(assigns.kind)])

    ~H"""
    <div {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  defp tile_kind_class(:primary), do: "tile--primary"
  defp tile_kind_class(:secondary), do: "tile--secondary"

  @doc """
  Renders an input with label and error messages.

  A `%Phoenix.HTML.Form{}` and field name may be passed to the input
  to build input names and error messages, or all the attributes and
  errors may be passed explicitly.

  ## Examples

      <.input field={@form[:email]} type="email" />
      <.input name="my-input" errors={["oh no!"]} />

  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any

  attr :type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file hidden money month number
               password range radio search select tel text time toggle-group url week)

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :helper, :string
  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"

  attr :options, :list,
    doc:
      "the options to pass to Phoenix.HTML.Form.options_for_select/2, or for the toggle-group input"

  attr :label_class, :any, default: nil, doc: "Extra classes to add to the label"
  attr :rest, :global, include: ~w(autocomplete cols disabled form max maxlength min minlength
                                   pattern placeholder readonly required rows size step)

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(errors, &translate_error(&1)))
    |> assign_new(:name, fn -> field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(%{type: "hidden"} = assigns) do
    ~H"""
    <input type="hidden" name={@name} id={@id || @name} value={@value} {@rest} />
    """
  end

  def input(%{type: "checkbox", value: value} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn -> Phoenix.HTML.Form.normalize_value("checkbox", value) end)

    ~H"""
    <div class="form-control-container">
      <input type="hidden" name={@name} value="false" />
      <.checkbox id={@id || @name} name={@name} value="true" checked={@checked} {@rest} />
      <label for={@id || @name}>{@label}</label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <div>
      <label for={@id || @name} class="label">{@label}</label>
      <.select id={@id} name={@name} prompt={@prompt} options={@options} value={@value} {@rest} />
      {input_helper_or_errors(assigns)}
    </div>
    """
  end

  def input(%{type: "money"} = assigns) do
    assigns =
      assign_new(assigns, :normalized_value, fn ->
        # XXX When supporting other currencies, the rounding must be done based on the
        # currency's precision.
        if assigns.value, do: Decimal.round(assigns.value.amount, 2)
      end)

    ~H"""
    <div>
      <label for={@id || @name} class="label">{@label}</label>
      <.text_input
        type="number"
        name={@name}
        id={@id || @name}
        value={Phoenix.HTML.Form.normalize_value("number", @normalized_value)}
        suffix={:currency_euro}
        step="0.01"
        {@rest}
      />
      {input_helper_or_errors(assigns)}
    </div>
    """
  end

  def input(assigns) do
    ~H"""
    <div>
      <label for={@id || @name} class="label">{@label}</label>
      <.text_input
        type={@type}
        name={@name}
        id={@id || @name}
        value={Phoenix.HTML.Form.normalize_value(@type, @value)}
        {@rest}
      />
      {input_helper_or_errors(assigns)}
    </div>
    """
  end

  defp input_helper_or_errors(%{errors: [], helper: _} = assigns), do: ~H|{@helper}|
  defp input_helper_or_errors(%{errors: []} = _assigns), do: nil
  defp input_helper_or_errors(assigns), do: ~H|<.error :for={msg <- @errors}>{msg}</.error>|

  @doc """
  Generates a generic error message.
  """
  slot :inner_block, required: true

  def error(assigns) do
    ~H"""
    <p class="text-red-500">{render_slot(@inner_block)}</p>
    """
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate "is invalid" in the "errors" domain
    #     dgettext("errors", "is invalid")
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # Because the error messages we show in our forms and APIs
    # are defined inside Ecto, we need to translate them dynamically.
    # This requires us to call the Gettext module passing our gettext
    # backend as first argument.
    #
    # Note we use the "errors" domain, which means translations
    # should be written to the errors.po file. The :count option is
    # set by Ecto and indicates we should also apply plural rules.
    if count = opts[:count] do
      Gettext.dngettext(AppWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(AppWeb.Gettext, "errors", msg, opts)
    end
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end
end
