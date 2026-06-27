defmodule App.Version do
  @moduledoc """
  This module embeds the application version, which is currently represented by the Git
  commit hash used when building the application.

  ## Why embed the version at compile-time?

  This ensures it is not overwritten by any kind of runtime configuration.

  ## Why read files here instead of in `config.exs`?

  To optimize the Docker image cache. Using `config.exs`, the information would need
  to be set when building dependencies with `mix deps.compile`. This implies the `.git`
  directory must be copied before compiling the dependencies, which would invalidate
  the cache even when dependencies did not change.
  """

  # The HEAD contains either `ref: refs/heads/...`
  # or a commit hash directly.
  case File.read(".git/HEAD") do
    {:ok, "ref: " <> ref} ->
      @app_version File.read!(".git/#{String.trim(ref)}") |> String.trim()

    {:ok, commit_sha} when byte_size(commit_sha) > 0 ->
      @app_version String.trim(commit_sha)

    {:error, _reason} ->
      if Mix.env() == :prod do
        raise "Could not compile: git commit not found"
      else
        @app_version "not_found"
      end
  end

  def version, do: @app_version
end
