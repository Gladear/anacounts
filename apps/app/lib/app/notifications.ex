defmodule App.Notifications do
  @moduledoc """
  The Notifications context. Create, read and delete notifications.

  See [App.Notifications.Notification](App.Notifications.Notification.html)
  for more information about notifications.
  """

  import Ecto.Query
  alias App.Repo

  alias App.Auth.User
  alias App.Notifications.Notification
  alias App.Notifications.Recipient

  @doc """
  Returns the list of notifications for a given user.

  ## Examples

      iex> list_user_notifications()
      [%Notification{}, ...]

  """
  @spec list_user_notifications(User.t()) :: [Notification.t()]
  def list_user_notifications(%User{} = user) do
    user_notifications_query(user.id)
    |> Repo.all()
  end

  # Returns a query fetching notifications for a given user.
  defp user_notifications_query(user_id) do
    from notification in Notification,
      join: recipient in assoc(notification, :recipients),
      where: recipient.user_id == ^user_id,
      select_merge: %{read_at: recipient.read_at},
      order_by: [asc: notification.inserted_at]
  end

  @doc """
  Gets a single notification.

  Raises `Ecto.NoResultsError` if the Notification does not exist.

  ## Examples

      iex> get_notification!(123)
      %Notification{}

      iex> get_notification!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_notification!(Notification.id()) :: Notification.t()
  def get_notification!(id), do: Repo.get!(Notification, id)

  @doc """
  Get a notification recipient from its user.

  Raises `Ecto.NoResultsError` if the Recipient does not exist.

  ## Examples

      iex> get_recipient!(123, 123)
      %Recipient{}

      iex> get_recipient!(456, 456)
      ** (Ecto.NoResultsError)

  """
  @spec get_recipient!(Notification.id(), User.id()) :: Recipient.t()
  def get_recipient!(notification_id, user_id),
    do: Repo.get_by!(Recipient, notification_id: notification_id, user_id: user_id)

  @doc """
  Creates a notification, and send it to the given users.

  ## Examples

      iex> create_notification(%{field: value}, [%User{}])
      {:ok, %Notification{}}

      iex> create_notification(%{field: bad_value}, [%User{}])
      {:error, %Ecto.Changeset{}}

  """

  @spec create_notification(map(), [User.t()]) ::
          {:ok, Notification.t()} | {:error, Ecto.Changeset.t()}
  def create_notification(attrs, recipients) when is_map(attrs) and is_list(recipients) do
    case insert_notification_with_recipients(attrs, recipients) do
      {:ok, result} ->
        {:ok, result.notification}

      {:error, :notification, changeset, _changes} ->
        {:error, changeset}
    end
  end

  defp insert_notification_with_recipients(attrs, recipients) do
    now =
      NaiveDateTime.utc_now()
      |> NaiveDateTime.truncate(:second)

    Ecto.Multi.new()
    |> Ecto.Multi.insert(:notification, Notification.changeset(%Notification{}, attrs))
    |> Ecto.Multi.insert_all(
      :recipients,
      Recipient,
      fn %{notification: notification} ->
        recipients
        |> Enum.uniq_by(& &1.id)
        |> Enum.map(fn %User{} = recipient ->
          %{
            user_id: recipient.id,
            notification_id: notification.id,
            inserted_at: now,
            updated_at: now
          }
        end)
      end
    )
    |> Repo.transaction()
  end

  @doc """
  Marks a notification as read. The `:read_at` field is set to the current time.
  If the notification was already read, the `:read_at` is kept unchanged.

  Fails if the notification was not sent to the given user.

  ## Examples

      iex> read_notification(user, notification)
      %Notification{}

      iex> read_notification(user, notification_not_for_user)
      ** (Ecto.NoResultsError)

  """
  @spec read_notification(User.t(), Notification.t()) :: {:ok, Notification.t()}
  def read_notification(%User{} = user, %Notification{} = notification) do
    recipient = Repo.get_by!(Recipient, user_id: user.id, notification_id: notification.id)

    if recipient.read_at do
      {:ok, notification}
    else
      updated_recipient =
        recipient
        |> Recipient.changeset(%{read_at: NaiveDateTime.utc_now()})
        |> Repo.update!()

      {:ok, %{notification | read_at: updated_recipient.read_at}}
    end
  end

  @doc """
  Check if a notification was read.

  This function result is based on the `:read_at` virtual field of the notification,
  therefore, it expects the `:read_at` field to be filled.

  To check if a notification was read by a certain user, use `read?/2` instead.

  ## Examples

      iex> read?(%Notification{read_at: ~N[2019-01-01 00:00:00]})
      true

      iex> read?(%Notification{read_at: nil})
      false

  """
  def read?(%Notification{} = notification) do
    notification.read_at != nil
  end

  @doc """
  Check if a notification was read by a given user.

  Raises `Ecto.NoResultsError` if the notification was not sent to the user.

  ## Examples

      iex> read?(user, notification)
      true

      iex> read?(user, notification_not_for_user)
      ** (Ecto.NoResultsError)

  """
  @spec read?(User.t(), Notification.t()) :: boolean()
  def read?(%User{} = user, %Notification{} = notification) do
    recipient = Repo.get_by!(Recipient, user_id: user.id, notification_id: notification.id)

    recipient.read_at != nil
  end

  @doc """
  Checks whether a notification is urgent or not.

  ## Examples

      iex> urgent?(%Notification{type: :admin_announcement})
      true

      iex> urgent?(%Notification{type: :other_type})
      false

  """
  @spec urgent?(Notification.t()) :: boolean()
  def urgent?(%Notification{} = notification) do
    notification.type == :admin_announcement
  end

  @doc """
  Deletes a notification.

  ## Examples

      iex> delete_notification(notification)
      {:ok, %Notification{}}

      iex> delete_notification(notification)
      {:error, %Ecto.Changeset{}}

  """
  @spec delete_notification(Notification.t()) ::
          {:ok, Notification.t()} | {:error, Ecto.Changeset.t()}
  def delete_notification(%Notification{} = notification) do
    Repo.delete(notification)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking notification changes.

  ## Examples

      iex> change_notification(notification)
      %Ecto.Changeset{data: %Notification{}}

  """
  @spec change_notification(Notification.t()) :: Ecto.Changeset.t(Notification.t())
  def change_notification(%Notification{} = notification, attrs \\ %{}) do
    Notification.changeset(notification, attrs)
  end
end
