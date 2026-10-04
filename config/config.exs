# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

# Configures the endpoint
config :app, AppWeb.Endpoint,
  render_errors: [
    formats: [html: AppWeb.ErrorHTML, json: AppWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: App.PubSub,
  live_view: [signing_salt: "F5OA2rrK"]

# Configure Mix tasks and generators
config :app,
  ecto_repos: [App.Repo],
  generators: [context_app: :app]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.25.4",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets --external:/fonts/* --external:/images/* --alias:@=.),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

# ## Internationalization
#
# Configure your application's default locale and more.
config :gettext, :default_locale, "en"

config :localize,
  default_locale: :en,
  supported_locales: [:en, :fr]

# Configures Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.4.3",
  default: [
    args: ~w(
      --config=assets/tailwind.config.js
      --input=assets/css/app.css
      --output=priv/static/assets/app.css
    ),
    cd: Path.expand("..", __DIR__)
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
