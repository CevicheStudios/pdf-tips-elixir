defmodule PdfTipsElixir.Repo.Migrations.AddPowerAutomateUrlToAppSettings do
  use Ecto.Migration

  def change do
    alter table(:app_settings) do
      add :power_automate_url, :binary
    end
  end
end
