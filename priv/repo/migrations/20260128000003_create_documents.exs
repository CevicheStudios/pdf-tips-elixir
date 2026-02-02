defmodule PdfTipsElixir.Repo.Migrations.CreateDocuments do
  use Ecto.Migration

  def change do
    create table(:documents) do
      add :name, :string, null: false
      add :file_path, :string
      add :content, :text
      add :page_count, :integer
      add :processed, :boolean, default: false, null: false
      add :source_type, :string, default: "pdf", null: false
      add :source_url, :string

      timestamps(type: :utc_datetime)
    end

    create index(:documents, [:source_type])
  end
end
