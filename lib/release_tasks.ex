defmodule App.ReleaseTasks do
  @moduledoc """
  Tasks to be done before launching a new release.
  """

  require Logger

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
    Logger.info("***** RUNNING MIGRATIONS *****")
    {:ok, _} = Application.ensure_all_started(:app)

    path = Application.app_dir(:app, "priv/repo/migrations")

    Ecto.Migrator.run(App.Repo, path, :up, all: true)
    Logger.info("***** FINISHED MIGRATIONS *****")
  end

  @doc """
  Run Ecto's data migrations. The migrations will permenantly alter the data in
  the database. They can take times and should be able to be cancelled and restarted
  without causing any problems.

  A guide to correctly writing data migrations was published by Fly, and can be found
  [on their blog](https://fly.io/phoenix-files/backfilling-data/).
  """
  def migrate_data do
    Logger.info("***** RUNNING DATA MIGRATIONS *****")
    {:ok, _} = Application.ensure_all_started(:app)

    path = Application.app_dir(:app, "priv/repo/data_migrations")

    Ecto.Migrator.run(App.Repo, path, :up, all: true)
    Logger.info("***** FINISHED DATA MIGRATIONS *****")
  end
end
