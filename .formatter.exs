[
  import_deps: [:ecto, :ecto_sql, :phoenix],
  subdirectories: ["priv/*/migrations"],
  plugins: [Styler, Phoenix.LiveView.HTMLFormatter],
  line_length: 98,
  tag_formatters: %{script: AppWeb.Prettier},
  inputs: ["*.{heex,ex,exs}", "{config,lib,test}/**/*.{heex,ex,exs}", "priv/*/seeds.exs"]
]
