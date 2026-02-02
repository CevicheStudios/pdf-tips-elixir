defmodule PdfTipsElixir.Repo.Migrations.CreateAppSettings do
  use Ecto.Migration

  def change do
    create table(:app_settings) do
      # Encrypted fields stored as binary
      add :anthropic_api_key, :binary
      add :voyage_api_key, :binary
      add :teams_webhook_url, :binary
      add :voyage_tokens_used, :bigint, default: 0, null: false

      timestamps(type: :utc_datetime)
    end
  end
end
