defmodule ReservationApp.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ReservationAppWeb.Telemetry,
      ReservationApp.Repo,
      {DNSCluster, query: Application.get_env(:reservation_app, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: ReservationApp.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: ReservationApp.Finch},
      # Start a worker by calling: ReservationApp.Worker.start_link(arg)
      # {ReservationApp.Worker, arg},
      # Start to serve requests, typically the last entry
      ReservationAppWeb.Endpoint,
      ReservationApp.LocksServer
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ReservationApp.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ReservationAppWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
