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
      {Finch, name: Swoosh.Finch}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: App.Supervisor)
  end
end
