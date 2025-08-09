defmodule App.Encrypted.Integer do
  @moduledoc """
  An `Ecto.Type` to encrypt integer fields.

  Implementation for `App.Vault`.

  ## Usage

  Create a database field of type `:binary`:
  ```ex
    add :encrypted_field, :binary
  ```

  Then use it as the type of your desired field:
  ```ex
    field :encrypted_field, MyApp.Encrypted.Integer
  ```
  """

  use Cloak.Ecto.Integer, vault: App.Vault
end
