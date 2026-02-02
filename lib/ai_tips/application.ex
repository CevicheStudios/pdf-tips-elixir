defmodule AiTips.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      AiTipsWeb.Telemetry,
      AiTips.Repo,
      {DNSCluster, query: Application.get_env(:ai_tips, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: AiTips.PubSub},
      # Cloak Vault for encryption
      AiTips.Vault,
      # Oban for background jobs
      {Oban, Application.fetch_env!(:ai_tips, Oban)},
      # Start to serve requests, typically the last entry
      AiTipsWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: AiTips.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    AiTipsWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
