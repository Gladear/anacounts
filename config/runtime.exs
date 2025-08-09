import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/tmp_phx start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") do
  config :app, AppWeb.Endpoint, server: true
end

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  config :app, App.Repo,
    # ssl: true,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    socket_options: maybe_ipv6

  # Configure Cloak's vault
  cloak_key =
    System.get_env("CLOAK_KEY") ||
      raise "environment variable CLOAK_KEY is missing."

  config :app, App.Vault,
    ciphers: [
      default:
        {Cloak.Ciphers.AES.GCM, tag: "AES.GCM.V1", key: Base.decode64!(cloak_key), iv_length: 12}
    ]

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

  config :app, AppWeb.Endpoint,
    url: [host: host, port: 80],
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: String.to_integer(System.get_env("PORT") || "4000")
    ],
    secret_key_base: secret_key_base

  # ## Configuring the mailer
  #
  # Configure Swoosh to use the SES adapter.

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
end
