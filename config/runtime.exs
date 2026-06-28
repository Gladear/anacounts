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

# ## Phoenix Endpoint
# Configure the Phoenix endpoint to start the server on the correct port and host.

# The `binding_*` variables are the one used by Phoenix to bind to a specified port
# and address. Phoenix will listen the incoming requests on the configured IP and port.
{binding_ip, binding_port} =
  case config_env() do
    :prod ->
      port = System.get_env("PORT") || "4000"

      # Enable IPv6 and bind on all interfaces.
      {{0, 0, 0, 0, 0, 0, 0, 0}, port}

    :dev ->
      # Binding to loopback ipv4 address prevents access from other machines.
      {{127, 0, 0, 1}, 4000}

    :test ->
      {{127, 0, 0, 1}, 4002}
  end

# The `exposed_*` variables are the one used to generate the URLs in the application,
# through Phoenix' verified routes. They may be reused by further configuration which
# may need to generate URLs, know the host of the application, etc.

{exposed_scheme, exposed_host, exposed_port} =
  cond do
    config_env() == :test ->
      {"http", "localhost", binding_port}

    host = System.get_env("HOST") ->
      # Assume that if the host is configured in dev, it's that people want to access
      # the app through a reverse-proxy for HTTPS access.
      {"https", host, 443}

    config_env() == :prod ->
      raise """
      environment variable HOST is missing.
      """

    true ->
      {"http", "localhost", binding_port}
  end

# The secret key base is used to sign/encrypt cookies and other secrets.
# A default value is used for :dev and :test environments, but we don't
# to check the :prod value into version control, so we use an environment
# variable instead.
secret_key_base =
  case config_env() do
    :prod ->
      System.get_env("SECRET_KEY_BASE") ||
        raise """
        environment variable SECRET_KEY_BASE is missing.
        You can generate one by calling: mix phx.gen.secret
        """

    :dev ->
      "Y8PSvX0+ZmmWKSfOyF3MRuaFKjHRwPA8IZKDm3A8RjiRF4jIoNq6cE07D1XWEdvV"

    :test ->
      "GHLDzAtB0iRfyK+gf+IQv69IFSZXgXQoYGyektl5fk90x/dxOW2WZ2OhH3XYvpK3"
  end

config :app, AppWeb.Endpoint,
  url: [host: exposed_host, port: exposed_port, scheme: exposed_scheme],
  secret_key_base: secret_key_base,
  http: [ip: binding_ip, port: binding_port]

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

## Internationalization

config :localize, supported_locales: Gettext.known_locales(AppWeb.Gettext)
