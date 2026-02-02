defmodule PdfTipsElixir.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      PdfTipsElixirWeb.Telemetry,
      PdfTipsElixir.Repo,
      {DNSCluster, query: Application.get_env(:pdf_tips_elixir, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: PdfTipsElixir.PubSub},
      # Cloak Vault for encryption
      PdfTipsElixir.Vault,
      # Oban for background jobs
      {Oban, Application.fetch_env!(:pdf_tips_elixir, Oban)},
      # Start to serve requests, typically the last entry
      PdfTipsElixirWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PdfTipsElixir.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    PdfTipsElixirWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
