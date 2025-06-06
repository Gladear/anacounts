[
  import_deps: [:ecto, :ecto_sql],
  subdirectories: [
    "priv/*/data_migrations",
    "priv/*/migrations"
  ],
  plugins: [Phoenix.LiveView.HTMLFormatter],
  inputs: ["*.{heex,ex,exs}", "{config,lib,test}/**/*.{heex,ex,exs}", "priv/*/seeds.exs"]
]
