defmodule App.Release do
  @moduledoc """
  Used for executing DB release tasks when run in production without Mix
  installed.
  """
  @app :app

  @doc """
  Run Ecto's ddl migrations. These are migrations that modify the database schema,
  but not the data.

  This function is called by the `start_commands.sh` script before the release is
  started.

  A guide to writing safe migrations was published by Fly, and can be found
  [on their blog](https://fly.io/phoenix-files/safe-ecto-migrations/).
  There are also up-to-date migration recipes on their
  [GitHub repo](https://github.com/fly-apps/safe-ecto-migrations).
  """
  def migrate do
    load_app()

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  @doc """
  Run Ecto's data migrations. The migrations will permenantly alter the data in
  the database. They can take time, and should be able to be cancelled and restarted
  without causing any problem.

  A guide to correctly writing data migrations was published by Fly, and can be found
  [on their blog](https://fly.io/phoenix-files/backfilling-data/).
  """
  def migrate_data do
    load_app()

    path = Application.app_dir(:app, "priv/repo/data_migrations")

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, path, :up, all: true))
    end
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    Application.load(@app)
  end
end
