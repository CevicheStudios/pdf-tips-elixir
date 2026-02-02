defmodule PdfTipsElixir.Knowledge.ChunkVector do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias PdfTipsElixir.Knowledge.Chunk
  alias PdfTipsElixir.Repo

  schema "chunk_vectors" do
    field :embedding, Pgvector.Ecto.Vector

    belongs_to :chunk, Chunk

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(chunk_vector, attrs) do
    chunk_vector
    |> cast(attrs, [:embedding, :chunk_id])
    |> validate_required([:embedding, :chunk_id])
    |> validate_embedding_dimensions()
    |> unique_constraint(:chunk_id)
    |> foreign_key_constraint(:chunk_id)
  end

  defp validate_embedding_dimensions(changeset) do
    case get_change(changeset, :embedding) do
      nil ->
        changeset

      %Pgvector{} = embedding ->
        if Pgvector.to_list(embedding) |> length() == 512 do
          changeset
        else
          add_error(changeset, :embedding, "must have exactly 512 dimensions")
        end

      embedding when is_list(embedding) ->
        if length(embedding) == 512 do
          changeset
        else
          add_error(changeset, :embedding, "must have exactly 512 dimensions")
        end
    end
  end

  @doc """
  Performs a cosine similarity search to find the most similar chunk vectors.

  ## Options
    * `:limit` - Maximum number of results (default: 5)
    * `:exclude_chunk_ids` - List of chunk IDs to exclude from results
  """
  def search(query_embedding, opts \\ []) do
    limit = Keyword.get(opts, :limit, 5)
    exclude_ids = Keyword.get(opts, :exclude_chunk_ids, [])

    # Convert list to Pgvector if needed
    query_vector =
      case query_embedding do
        %Pgvector{} -> query_embedding
        list when is_list(list) -> Pgvector.new(list)
      end

    base_query =
      from cv in __MODULE__,
        order_by: fragment("embedding <=> ?", ^query_vector),
        limit: ^limit,
        preload: [:chunk]

    query =
      if Enum.empty?(exclude_ids) do
        base_query
      else
        from cv in base_query, where: cv.chunk_id not in ^exclude_ids
      end

    Repo.all(query)
  end

  @doc """
  Calculates the cosine similarity between two embeddings.
  Returns a value between 0 and 1, where 1 is most similar.
  """
  def cosine_similarity(embedding1, embedding2) do
    list1 = to_list(embedding1)
    list2 = to_list(embedding2)

    dot_product = Enum.zip(list1, list2) |> Enum.map(fn {a, b} -> a * b end) |> Enum.sum()
    magnitude1 = :math.sqrt(Enum.map(list1, &(&1 * &1)) |> Enum.sum())
    magnitude2 = :math.sqrt(Enum.map(list2, &(&1 * &1)) |> Enum.sum())

    if magnitude1 == 0 or magnitude2 == 0 do
      0.0
    else
      # Convert from distance to similarity (cosine distance -> cosine similarity)
      (dot_product / (magnitude1 * magnitude2) + 1) / 2
    end
  end

  defp to_list(%Pgvector{} = v), do: Pgvector.to_list(v)
  defp to_list(list) when is_list(list), do: list
end
