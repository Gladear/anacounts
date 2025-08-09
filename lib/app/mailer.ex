defmodule App.Mailer do
  @moduledoc """
  Send emails from the app.
  """

  use Swoosh.Mailer, otp_app: :app

  @doc """
  Get the email address to use as the "from" address.
  """
  @spec no_reply_email() :: String.t()
  def no_reply_email, do: "noreply@#{identity()}"

  # retrieves the sender identity from the configuration
  defp identity do
    config = Application.get_env(:app, App.Mailer)
    config[:identity]
  end
end
