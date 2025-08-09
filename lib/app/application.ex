defmodule App.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl Application
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      App.Repo,
      # Start Cloak vault
      App.Vault,
      # Start the PubSub system
      {Phoenix.PubSub, name: App.PubSub},
      # Start Finch
      {Finch, name: Swoosh.Finch},
      # Start the Endpoint (http/https)
      AppWeb.Endpoint
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: App.Supervisor)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl Application
  def config_change(changed, _new, removed) do
    AppWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
