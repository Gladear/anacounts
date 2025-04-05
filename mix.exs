defmodule Anacounts.Umbrella.MixProject do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      version: "0.1.0",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      releases: [
        app_web: [
          applications: [
            app: :permanent,
            app_web: :permanent
          ]
        ]
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

  def cli do
    [
      preferred_envs: [
        dialyzer: :test
      ]
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options.
  #
  # Dependencies listed here are available only for this project
  # and cannot be accessed from applications inside the apps/ folder.
  defp deps do
    [
      # Required to run "mix format" on ~H/.heex files from the umbrella root
      {:phoenix_live_view, ">= 0.0.0"},

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
  #
  # Aliases listed here are available only for this project
  # and cannot be accessed from applications inside the apps/ folder.
  defp aliases do
    [
      # run `mix setup` in all child apps
      setup: ["cmd mix setup"],
      "assets.deploy": ["cmd --app app_web mix assets.deploy"],
      # generate a data migration, counterpart of `mix ecto.gen.migration`
      "ecto.gen.data_migration": ["cmd --app app mix ecto.gen.data_migration"],
      # run data migrations, counterpart of `mix ecto.migrate`
      "ecto.migrate_data": ["eval App.ReleaseTasks.migrate_data"]
    ]
  end
end
