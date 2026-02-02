defmodule PdfTipsElixir.Repo.Migrations.CreateTips do
  use Ecto.Migration

  def change do
    create table(:tips) do
      add :title, :string, null: false
      add :content, :text, null: false
      add :example, :text
      add :source_reference, :string
      add :posted, :boolean, default: false, null: false
      add :posted_at, :utc_datetime
      add :chunk_id, references(:chunks, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create index(:tips, [:chunk_id])
    create index(:tips, [:posted])
  end
end
