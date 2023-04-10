defmodule Instaclone.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      InstacloneWeb.Telemetry,
      # Start the Ecto repository
      Instaclone.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: Instaclone.PubSub},
      # Start Finch
      {Finch, name: Instaclone.Finch},
      # Start the Endpoint (http/https)
      InstacloneWeb.Endpoint
      # Start a worker by calling: Instaclone.Worker.start_link(arg)
      # {Instaclone.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Instaclone.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    InstacloneWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
