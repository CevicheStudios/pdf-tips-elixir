defmodule AiTips.Repo.Migrations.CreateChunkVectors do
  use Ecto.Migration

  def change do
    create table(:chunk_vectors) do
      add :embedding, :vector, size: 512, null: false
      add :chunk_id, references(:chunks, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:chunk_vectors, [:chunk_id])

    # Create IVFFlat index for approximate nearest neighbor search
    # Using 100 lists as a good default for medium-sized datasets
    execute """
    CREATE INDEX chunk_vectors_embedding_idx ON chunk_vectors
    USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100)
    """,
    "DROP INDEX IF EXISTS chunk_vectors_embedding_idx"
  end
end
