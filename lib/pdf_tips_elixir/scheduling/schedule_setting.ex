defmodule PdfTipsElixir.Scheduling.ScheduleSetting do
  use Ecto.Schema
  import Ecto.Changeset

  @schedules ~w(daily_9am daily_2pm weekly_monday weekly_friday)

  schema "schedule_settings" do
    field :enabled, :boolean, default: false
    field :schedule, :string, default: "daily_9am"
    field :topic, :string
    field :last_run_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(schedule_setting, attrs) do
    schedule_setting
    |> cast(attrs, [:enabled, :schedule, :topic, :last_run_at])
    |> validate_inclusion(:schedule, @schedules)
  end

  def schedules, do: @schedules

  def schedule_label("daily_9am"), do: "Daily at 9:00 AM"
  def schedule_label("daily_2pm"), do: "Daily at 2:00 PM"
  def schedule_label("weekly_monday"), do: "Weekly on Monday at 9:00 AM"
  def schedule_label("weekly_friday"), do: "Weekly on Friday at 2:00 PM"
  def schedule_label(_), do: "Unknown schedule"

  @doc """
  Converts a schedule string to an Oban cron expression.
  """
  def to_cron("daily_9am"), do: "0 9 * * *"
  def to_cron("daily_2pm"), do: "0 14 * * *"
  def to_cron("weekly_monday"), do: "0 9 * * 1"
  def to_cron("weekly_friday"), do: "0 14 * * 5"
  def to_cron(_), do: nil
end
