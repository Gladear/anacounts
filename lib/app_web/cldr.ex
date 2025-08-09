defmodule AppWeb.Cldr do
  @moduledoc """
  Define a backend module that hosts the
  Cldr configuration and public API.

  Most function calls in Cldr will be calls
  to functions on this module.
  """
  use Cldr,
    gettext: AppWeb.Gettext,
    providers: [Cldr.Number, Money]
end
