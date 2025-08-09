defmodule AppWeb.Layouts do
  @moduledoc """
  Templates for application layouts.
  """
  use AppWeb, :html

  embed_templates "layouts/*"
end
