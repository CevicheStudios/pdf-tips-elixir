defmodule PdfTipsElixir.Workers.PostScheduledTipWorker do
  @moduledoc """
  Oban worker for generating and posting scheduled tips to Teams.
  """

  use Oban.Worker,
    queue: :default,
    max_attempts: 3

  require Logger

  alias PdfTipsElixir.Scheduling
  alias PdfTipsElixir.Services.{TipGenerator, TeamsService}

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    topic = args["topic"]

    Logger.info("Running scheduled tip generation#{if topic, do: " for topic: #{topic}", else: ""}")

    # Check if scheduling is enabled
    unless Scheduling.enabled?() do
      Scheduling.log_skipped("Scheduling is disabled")
      Logger.info("Scheduled tip generation skipped: scheduling disabled")
      return_ok()
    end

    # Check if services are configured
    unless TipGenerator.configured?() do
      Scheduling.log_error("Anthropic API not configured")
      Logger.warning("Scheduled tip generation skipped: Anthropic not configured")
      return_ok()
    end

    unless TeamsService.configured?() do
      Scheduling.log_error("Teams webhook not configured")
      Logger.warning("Scheduled tip generation skipped: Teams not configured")
      return_ok()
    end

    # Generate tip
    opts = if topic, do: [topic: topic], else: []

    case TipGenerator.generate_tip(opts) do
      {:ok, tip} ->
        # Post to Teams
        case TeamsService.post_tip(tip) do
          {:ok, _} ->
            Scheduling.mark_as_run()
            Scheduling.log_success(tip)
            Logger.info("Scheduled tip posted successfully: #{tip.title}")
            :ok

          {:error, reason} ->
            Scheduling.log_error("Failed to post to Teams: #{reason}")
            Logger.error("Scheduled tip Teams post failed: #{reason}")
            {:error, reason}
        end

      {:error, reason} ->
        Scheduling.log_error("Failed to generate tip: #{reason}")
        Logger.error("Scheduled tip generation failed: #{reason}")
        {:error, reason}
    end
  end

  defp return_ok, do: :ok
end
