if Mix.env() == :dev do
  defmodule AppWeb.Prettier do
    @moduledoc """
    Formats colocated JS/CSS embedded in HEEx templates using prettier.

    Used by `mix format` through the `:tag_formatters` option in `.formatter.exs`.

    Copied from Phoenix LiveView's documentation:
    https://phoenix-live-view.hexdocs.pm/Phoenix.LiveView.HTMLFormatter.TagFormatter.html
    """

    @behaviour Phoenix.LiveView.HTMLFormatter.TagFormatter

    require Logger

    @impl Phoenix.LiveView.HTMLFormatter.TagFormatter
    def render_tag({"script", attrs, content}, _opts) do
      suffix =
        case attrs do
          %{":type" => _} ->
            # assume ColocatedHook / ColocatedJS and check for extension in manifest attribute
            Map.get(attrs, "manifest", "index.js")

          _ ->
            "tmp.js"
        end

      tmp_file =
        Path.join(System.tmp_dir!(), "prettier_#{System.unique_integer([:positive])}_#{suffix}")

      try do
        File.write!(tmp_file, content)

        case System.cmd("npx", ["prettier", tmp_file], stderr_to_stdout: true) do
          {output, 0} ->
            {:ok, String.trim(output)}

          {error, _} ->
            Logger.error("Failed to format with prettier: #{error}")
            :skip
        end
      after
        File.rm(tmp_file)
      end
    end
  end
end
