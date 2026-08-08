defmodule App.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `App.Accounts` context.
  """

  alias App.Accounts
  alias App.Accounts.UserPasskey
  alias App.Repo

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"

  def user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_user_email(),
      password: "hello world!"
    })
  end

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> user_attributes()
      |> Accounts.register_user()

    user
  end

  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end

  def user_passkey_fixture(user, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        user_id: user.id,
        device_name: "Test Passkey #{System.unique_integer()}",
        credential_id: :crypto.strong_rand_bytes(16),
        public_key: :crypto.strong_rand_bytes(32),
        sign_count: 0
      })

    %UserPasskey{}
    |> Ecto.Changeset.change(attrs)
    |> Repo.insert!()
  end
end
