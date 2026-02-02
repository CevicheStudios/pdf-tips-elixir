defmodule PdfTipsElixir.Repo.Migrations.CreateScheduleSettings do
  use Ecto.Migration

  def change do
    create table(:schedule_settings) do
      add :enabled, :boolean, default: false, null: false
      add :schedule, :string, default: "daily_9am", null: false
      add :topic, :string
      add :last_run_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end
  end
end
