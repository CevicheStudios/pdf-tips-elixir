defmodule PdfTipsElixir.Repo.Migrations.CreateChunks do
  use Ecto.Migration

  def change do
    create table(:chunks) do
      add :content, :text, null: false
      add :page_number, :integer
      add :chunk_index, :integer, null: false
      add :times_used, :integer, default: 0, null: false
      add :last_used_at, :utc_datetime
      add :document_id, references(:documents, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:chunks, [:document_id])
    create index(:chunks, [:times_used])
  end
end
