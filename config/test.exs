import Config

# Only in tests, remove the complexity from the password hashing algorithm
config :bcrypt_elixir, :log_rounds, 1

# Configure Cloak's vault
config :app, App.Vault,
  ciphers: [
    default:
      {Cloak.Ciphers.AES.GCM,
       tag: "AES.GCM.V1",
       key: Base.decode64!("ZQDBZYVMOjxGEUYGYYMZnP7pYe8IK5QLR7kRz8wYJRk="),
       iv_length: 12}
  ]

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :app, AppWeb.Endpoint, server: false

# Print only warnings and errors during test
config :logger, level: :warning

# In test we don't send emails.
config :app, App.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
