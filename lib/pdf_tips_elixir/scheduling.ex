defmodule PdfTipsElixir.Scheduling do
  @moduledoc """
  The Scheduling context for managing scheduled tip generation.
  """

  import Ecto.Query, warn: false
  alias PdfTipsElixir.Repo
  alias PdfTipsElixir.Scheduling.{ScheduleSetting, ScheduleLog}

  # Schedule Settings (singleton)

  @doc """
  Gets the current schedule settings (singleton pattern).
  Creates a new record if none exists.
  """
  def current_settings do
    case Repo.one(from s in ScheduleSetting, limit: 1) do
      nil ->
        {:ok, setting} = Repo.insert(%ScheduleSetting{})
        setting

      setting ->
        setting
    end
  end

  @doc """
  Updates the schedule settings.
  """
  def update_settings(attrs) do
    current_settings()
    |> ScheduleSetting.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Enables scheduled tip generation.
  """
  def enable_scheduling do
    update_settings(%{enabled: true})
  end

  @doc """
  Disables scheduled tip generation.
  """
  def disable_scheduling do
    update_settings(%{enabled: false})
  end

  @doc """
  Updates the last run timestamp.
  """
  def mark_as_run do
    update_settings(%{last_run_at: DateTime.utc_now() |> DateTime.truncate(:second)})
  end

  @doc """
  Checks if scheduling is enabled.
  """
  def enabled? do
    current_settings().enabled
  end

  # Schedule Logs

  @doc """
  Returns the list of schedule logs.
  """
  def list_logs(opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)

    from(l in ScheduleLog,
      order_by: [desc: l.inserted_at],
      limit: ^limit,
      preload: [:tip]
    )
    |> Repo.all()
  end

  @doc """
  Creates a schedule log entry.
  """
  def create_log(attrs \\ %{}) do
    %ScheduleLog{}
    |> ScheduleLog.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Logs a successful scheduled run.
  """
  def log_success(tip) do
    create_log(%{
      status: "success",
      message: "Generated and posted tip: #{tip.title}",
      tip_id: tip.id
    })
  end

  @doc """
  Logs an error during scheduled run.
  """
  def log_error(message) do
    create_log(%{
      status: "error",
      message: message
    })
  end

  @doc """
  Logs a skipped scheduled run.
  """
  def log_skipped(reason) do
    create_log(%{
      status: "skipped",
      message: reason
    })
  end
end
