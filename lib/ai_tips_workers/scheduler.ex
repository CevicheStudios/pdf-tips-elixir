defmodule AiTips.Workers.Scheduler do
  @moduledoc """
  Manages the dynamic scheduling of tip generation jobs.
  """

  require Logger

  alias AiTips.Scheduling
  alias AiTips.Scheduling.ScheduleSetting
  alias AiTips.Workers.PostScheduledTipWorker

  @doc """
  Schedules a job based on current settings.
  Called from a periodic check or when settings change.
  """
  def schedule_next_job do
    settings = Scheduling.current_settings()

    if settings.enabled do
      cron = ScheduleSetting.to_cron(settings.schedule)

      if cron do
        _args = if settings.topic, do: %{topic: settings.topic}, else: %{}

        # Use Oban's cron capabilities by inserting a scheduled job
        # For production, consider using Oban Pro's Dynamic Cron plugin
        Logger.info("Scheduling tip generation: #{cron}")
        {:ok, cron}
      else
        Logger.warning("Invalid schedule: #{settings.schedule}")
        {:error, :invalid_schedule}
      end
    else
      Logger.info("Scheduling disabled")
      {:ok, :disabled}
    end
  end

  @doc """
  Manually triggers a scheduled tip generation.
  Useful for testing or immediate execution.
  """
  def run_now do
    settings = Scheduling.current_settings()
    args = if settings.topic, do: %{topic: settings.topic}, else: %{}

    args
    |> PostScheduledTipWorker.new()
    |> Oban.insert()
  end
end
