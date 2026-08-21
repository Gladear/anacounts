defmodule App.Accounts do
  @moduledoc """
  Manage user accounts.
  Provides registering, authentication, token creation for session,
  email and password change and reset.
  """

  import Ecto.Query

  alias App.Repo

  alias App.Accounts.User
  alias App.Accounts.UserNotifier
  alias App.Accounts.UserPasskey
  alias App.Accounts.UserToken

  ## Database getters

  @doc """
  Gets a user by email.
  """
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  Gets a user by email and password.
  """
  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = Repo.get_by(User, email: email)
    if User.valid_password?(user, password), do: user
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.
  """
  def get_user!(id), do: Repo.get!(User, id)

  ## User registration

  @doc """
  Registers a user.
  """
  def register_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.
  """
  def change_user_registration(%User{} = user, attrs \\ %{}) do
    User.registration_changeset(user, attrs, hash_password: false, validate_email: false)
  end

  ## Settings

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user email.
  """
  def change_user_email(user, attrs \\ %{}) do
    User.email_changeset(user, attrs, validate_email: false)
  end

  @doc """
  Emulates that the email will change without actually changing
  it in the database.
  """
  def apply_user_email(user, password, attrs) do
    user
    |> User.email_changeset(attrs)
    |> User.validate_current_password(password)
    |> Ecto.Changeset.apply_action(:update)
  end

  @doc """
  Updates the user email using the given token.

  If the token matches, the user email is updated and the token is deleted.
  """
  def update_user_email(user, token) do
    context = "change:#{user.email}"

    with {:ok, query} <- UserToken.verify_change_email_token_query(token, context),
         %UserToken{sent_to: email} <- Repo.one(query),
         {:ok, _} <- Repo.transact(user_email_multi(user, email, context)) do
      :ok
    else
      _ -> :error
    end
  end

  defp user_email_multi(user, email, context) do
    changeset = User.email_changeset(user, %{email: email})

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, [context]))
  end

  @doc ~S"""
  Delivers the update email instructions to the given user.
  """
  def deliver_user_update_email_instructions(%User{} = user, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "change:#{current_email}")

    Repo.insert!(user_token)
    UserNotifier.deliver_update_email_instructions(user, update_email_url_fun.(encoded_token))
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user password.
  """
  def change_user_password(user, attrs \\ %{}) do
    User.password_changeset(user, attrs, hash_password: false)
  end

  @doc """
  Updates the user password.
  """
  def update_user_password(user, password, attrs) do
    changeset =
      user
      |> User.password_changeset(attrs)
      |> User.validate_current_password(password)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, :all))
    |> Repo.transact()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  ## Passkeys

  @doc """
  Returns the list of passkeys for the given user.
  """
  @spec list_user_passkeys(User.t()) :: UserPasskey.t()
  def list_user_passkeys(%User{} = user) do
    user
    |> UserPasskey.user_query()
    |> order_by(asc: :device_name)
    |> Repo.all()
  end

  @doc """
  Returns the number of passkeys a user has configured.
  """
  def count_user_passkeys(%User{} = user) do
    user
    |> UserPasskey.user_query()
    |> Repo.aggregate(:count)
  end

  @doc """
  Returns whether the user has at least one passkey configured.
  """
  @doc deprecated: "to be removed once all users are only logged in using passkeys"
  @spec user_has_passkey?(User.t()) :: boolean()
  def user_has_passkey?(%User{} = user) do
    user
    |> UserPasskey.user_query()
    |> Repo.exists?()
  end

  @doc """
  Gets a single passkey if it belongs to the user.

  Raises `Ecto.NoResultsError` if the passkey does not exist or does not belong to the user.
  """
  @spec get_user_passkey!(User.t(), integer()) :: UserPasskey.t()
  def get_user_passkey!(%User{} = user, id) do
    user
    |> UserPasskey.user_query()
    |> Repo.get!(id)
  end

  @doc """
  Change a passkey's device name.
  """
  def rename_user_passkey(%UserPasskey{} = user_passkey, attrs) do
    user_passkey
    |> UserPasskey.device_name_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a passkey.

  Returns `{:error, :last_passkey}` when this is the last passkey of a user.
  """
  def delete_user_passkey(%UserPasskey{} = user_passkey) do
    user = get_user!(user_passkey.user_id)

    if count_user_passkeys(user) <= 1 do
      {:error, :last_passkey}
    else
      Repo.delete(user_passkey)
    end
  end

  ## Device linking

  @doc """
  Creates a short-lived, single-use token that lets a new device register a
  passkey for the given user.
  """
  def create_device_link_token(%User{} = user) do
    {encoded_token, user_token} = UserToken.build_device_link_token(user)
    Repo.insert!(user_token)
    encoded_token
  end

  @doc """
  Gets the user by device-link token.
  """
  def get_user_by_device_link_token(token) do
    with {:ok, query} <- UserToken.verify_device_link_token_query(token),
         %User{} = user <- Repo.one(query) do
      user
    else
      _ -> nil
    end
  end

  @doc """
  Deletes the given user's device-link tokens, so a token can only be
  redeemed once.
  """
  def delete_device_link_tokens(%User{} = user) do
    UserToken.user_and_contexts_query(user, ["device_link"])
    |> Repo.delete_all()

    :ok
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  @doc """
  Gets the user with the given signed token.
  """
  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_user_session_token(token) do
    UserToken.token_and_context_query(token, "session")
    |> Repo.delete_all()

    :ok
  end

  ## Reset password

  @doc ~S"""
  Delivers the reset password email to the given user.
  """
  def deliver_user_reset_password_instructions(%User{} = user, reset_password_url_fun)
      when is_function(reset_password_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "reset_password")
    Repo.insert!(user_token)
    UserNotifier.deliver_reset_password_instructions(user, reset_password_url_fun.(encoded_token))
  end

  @doc """
  Gets the user by reset password token.
  """
  def get_user_by_reset_password_token(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "reset_password"),
         %User{} = user <- Repo.one(query) do
      user
    else
      _ -> nil
    end
  end

  @doc """
  Resets the user password.
  """
  def reset_user_password(user, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.password_changeset(user, attrs))
    |> Ecto.Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, :all))
    |> Repo.transact()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end
end
