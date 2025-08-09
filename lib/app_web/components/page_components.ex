defmodule AppWeb.PageComponents do
  @moduledoc """
  A module defining complex components for live views.

  The components defined here are based on the components defined in
  `AppWeb.CoreComponents`. They are more complex and usually only fit
  in more specific contexts.
  """

  use AppWeb, :gettext
  use AppWeb, :verified_routes
  use Phoenix.Component

  import AppWeb.CoreComponents

  ## App page

  @doc """
  The app page contains part of the layout of most pages of the application.

  It includes the breadcrumb, title, and the main content of the page.
  """

  slot :breadcrumb, required: true
  slot :title, required: true

  def app_page(assigns) do
    ~H"""
    <div class="app-page">
      <header>
        <.breadcrumb>
          <.breadcrumb_home navigate={~p"/books"} alt={gettext("Home")} />
          {render_slot(@breadcrumb)}
        </.breadcrumb>
        <h1 class="title-1 truncate">{render_slot(@title)}</h1>
      </header>
      <main>
        {render_slot(@inner_block)}
      </main>
    </div>
    """
  end
end
