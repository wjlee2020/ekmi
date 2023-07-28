defmodule Ekmi.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      EkmiWeb.Telemetry,
      # Start the Ecto repository
      Ekmi.Repo,
      # Oban
      {Oban, Application.fetch_env!(:ekmi, Oban)},
      # Start the PubSub system
      {Phoenix.PubSub, name: Ekmi.PubSub},
      # Presence PubSub
      EkmiWeb.Presence,
      # Start Finch
      {Finch, name: Ekmi.Finch},
      # Start the Endpoint (http/https)
      EkmiWeb.Endpoint
      # Start a worker by calling: Ekmi.Worker.start_link(arg)
      # {Ekmi.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Ekmi.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    EkmiWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
