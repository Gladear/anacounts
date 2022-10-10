import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.
if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6"), do: [:inet6], else: []

  config :app, App.Repo,
    # ssl: true,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    socket_options: maybe_ipv6

  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  # For production, don't forget to configure the url host
  # to something meaningful, Phoenix uses this information
  # when generating URLs.

  host =
    System.get_env("HOST") ||
      raise "environment variable HOST is missing."

  config :app_web, AppWeb.Endpoint,
    url: [host: host, port: 80],
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: String.to_integer(System.get_env("PORT") || "4000")
    ],
    secret_key_base: secret_key_base

  # ## Using releases
  #
  # Configure for OTP releases, instruct Phoenix to start the endpoint

  config :app_web, AppWeb.Endpoint, server: true

  # ## Configuring the mailer
  #
  # In production you need to configure the mailer to use a different adapter.
  # Also, you may need to configure the Swoosh API client of your choice if you
  # are not using SMTP. Here is an example of the configuration:

  ses_region =
    System.get_env("SES_REGION") ||
      raise "environment variable SES_REGION is missing."

  ses_access_key =
    System.get_env("SES_ACCESS_KEY") ||
      raise "environment variable SES_ACCESS_KEY is missing."

  ses_secret_key =
    System.get_env("SES_SECRET_KEY") ||
      raise "environment variable SES_SECRET_KEY is missing."

  ses_identity =
    System.get_env("SES_IDENTITY") ||
      raise "environment variable SES_IDENTITY is missing."

  config :app, App.Mailer,
    adapter: Swoosh.Adapters.AmazonSES,
    region: ses_region,
    access_key: ses_access_key,
    secret: ses_secret_key,
    identity: ses_identity

  # A HTTP client is required by Swoosh API client for most providers (including SES).
  # Swoosh supports Hackney and Finch out of the box:

  config :swoosh, :api_client, Swoosh.ApiClient.Hackney
end
