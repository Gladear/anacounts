defmodule App.Vault do
  @moduledoc """
  Encrypts and decrypts data, using a configured cipher.

  Implementation of `Cloak.Vault`.
  """

  use Cloak.Vault, otp_app: :app
end
