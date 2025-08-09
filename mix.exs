defmodule App.MixProject do
  use Mix.Project

  def project do
    [
      app: :app,
      version: "0.1.0",
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      listeners: [Phoenix.CodeReloader],
      compilers: [:phoenix_live_view] ++ Mix.compilers(),
      gettext: [
        write_reference_comments: false,
        sort_by_msgid: :case_sensitive
      ],
      dialyzer: [
        list_unused_filters: true,
        # Put the project-level PLT in the priv/ directory
        # (instead of the default _build/ location)
        # for the CI to be able to cache it between builds
        plt_local_path: "priv/plts/project.plt",
        plt_core_path: "priv/plts/core.plt",
        # Add some apps to the list of apps included in the PLT.
        # - `:ex_unit` is required to type-check modules that `use ExUnit.CaseTemplate`
        plt_add_apps: [:ex_unit]
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {App.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  def cli do
    [
      preferred_envs: [
        dialyzer: :test
      ]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      ## Authentication
      {:bcrypt_elixir, "~> 3.1"},

      ## Business
      {:decimal, "~> 2.1"},
      {:phoenix_pubsub, "~> 2.1"},

      ## Database
      {:ecto_sql, "~> 3.9"},
      {:postgrex, ">= 0.0.0"},
      {:cloak_ecto, "~> 1.3.0"},
      {:ex_money, "~> 5.15"},
      {:ex_money_sql, "~> 1.9"},

      # Emails
      {:swoosh, "~> 1.13"},
      {:gen_smtp, "~> 1.2"},
      {:finch, "~> 0.18"},

      # Phoenix and server tooling
      {:phoenix, "~> 1.8"},
      {:phoenix_ecto, "~> 4.4"},
      {:phoenix_html, "~> 4.0"},
      {:phoenix_live_reload, "~> 1.4", only: :dev},
      {:phoenix_live_view, "~> 1.0"},
      {:phoenix_live_dashboard, "~> 0.8"},
      {:plug_cowboy, "~> 2.6"},

      # Front (tooling and assets)
      {:esbuild, "~> 0.8", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.2", runtime: Mix.env() == :dev},
      {:heroicons, "~> 0.5.5"},

      # Internationalization
      {:gettext, "~> 0.24"},
      {:ex_cldr, "~> 2.37"},
      {:ex_cldr_plugs, "~> 1.3"},

      # Tools
      {:lazy_html, ">= 0.0.0", only: :test},
      {:jason, "~> 1.4"},

      # Code analysis
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],

      ## Data related aliases
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      # Generate a data migration, counterpart of `mix ecto.gen.migration`
      "ecto.gen.data_migration": [
        "ecto.gen.migration --migrations-path priv/repo/data_migrations"
      ],
      # Run data migrations, counterpart of `mix ecto.migrate`
      "ecto.migrate_data": ["eval App.ReleaseTasks.migrate_data"],

      ## Web-related aliases
      gettext: ["gettext.extract --merge --no-fuzzy"],
      "assets.setup": [
        "cmd npm install --prefix assets",
        "tailwind.install --if-missing",
        "esbuild.install --if-missing"
      ],
      "assets.build": [
        "tailwind default",
        "esbuild default"
      ],
      "assets.deploy": [
        "cmd npm install --prefix assets",
        "tailwind default --minify",
        "esbuild default --minify",
        "phx.digest"
      ]
    ]
  end
end
