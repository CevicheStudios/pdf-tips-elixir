defmodule PdfTipsElixir.Repo.Migrations.CreateScheduleLogs do
  use Ecto.Migration

  def change do
    create table(:schedule_logs) do
      add :status, :string, null: false
      add :message, :text
      add :tip_id, references(:tips, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create index(:schedule_logs, [:tip_id])
  end
end
