defmodule PdfTipsElixir.Knowledge do
  @moduledoc """
  The Knowledge context for managing documents, chunks, and embeddings.
  """

  import Ecto.Query, warn: false
  alias PdfTipsElixir.Repo
  alias PdfTipsElixir.Knowledge.{Document, Chunk, ChunkVector}

  # Documents

  @doc """
  Returns the list of documents.
  """
  def list_documents do
    Document
    |> order_by([d], desc: d.inserted_at)
    |> Repo.all()
  end

  @doc """
  Gets a single document.
  """
  def get_document(id), do: Repo.get(Document, id)

  @doc """
  Gets a single document with chunks preloaded.
  """
  def get_document_with_chunks(id) do
    Document
    |> Repo.get(id)
    |> Repo.preload(chunks: from(c in Chunk, order_by: c.chunk_index))
  end

  @doc """
  Creates a document.
  """
  def create_document(attrs \\ %{}) do
    %Document{}
    |> Document.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a document.
  """
  def update_document(%Document{} = document, attrs) do
    document
    |> Document.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a document and its associated chunks.
  """
  def delete_document(%Document{} = document) do
    Repo.delete(document)
  end

  @doc """
  Returns the count of documents.
  """
  def count_documents do
    Repo.aggregate(Document, :count)
  end

  @doc """
  Returns the count of processed documents.
  """
  def count_processed_documents do
    from(d in Document, where: d.processed == true)
    |> Repo.aggregate(:count)
  end

  # Chunks

  @doc """
  Returns the list of chunks for a document.
  """
  def list_chunks_for_document(document_id) do
    from(c in Chunk,
      where: c.document_id == ^document_id,
      order_by: c.chunk_index,
      preload: [:chunk_vector]
    )
    |> Repo.all()
  end

  @doc """
  Gets a single chunk with document preloaded.
  """
  def get_chunk(id) do
    Chunk
    |> Repo.get(id)
    |> Repo.preload([:document, :chunk_vector])
  end

  @doc """
  Creates a chunk.
  """
  def create_chunk(attrs \\ %{}) do
    %Chunk{}
    |> Chunk.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Creates multiple chunks for a document.
  """
  def create_chunks(document_id, chunks_data) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    chunks =
      Enum.map(chunks_data, fn data ->
        %{
          document_id: document_id,
          content: data.content,
          page_number: data[:page_number],
          chunk_index: data.chunk_index,
          times_used: 0,
          inserted_at: now,
          updated_at: now
        }
      end)

    Repo.insert_all(Chunk, chunks)
  end

  @doc """
  Marks a chunk as used for tip generation.
  """
  def mark_chunk_as_used(%Chunk{} = chunk) do
    chunk
    |> Chunk.mark_as_used()
    |> Repo.update()
  end

  @doc """
  Returns chunks available for tip generation.
  """
  def list_available_chunks(opts \\ []) do
    limit = Keyword.get(opts, :limit, 10)
    document_id = Keyword.get(opts, :document_id)

    query =
      Chunk.available_for_tips()
      |> preload(:document)
      |> limit(^limit)

    query =
      if document_id do
        where(query, [c], c.document_id == ^document_id)
      else
        query
      end

    Repo.all(query)
  end

  @doc """
  Returns a random available chunk for tip generation.
  """
  def get_random_available_chunk(opts \\ []) do
    document_id = Keyword.get(opts, :document_id)

    query =
      Chunk.available_for_tips()
      |> preload(:document)
      |> order_by(fragment("RANDOM()"))
      |> limit(1)

    query =
      if document_id do
        where(query, [c], c.document_id == ^document_id)
      else
        query
      end

    Repo.one(query)
  end

  @doc """
  Returns the total count of chunks.
  """
  def count_chunks do
    Repo.aggregate(Chunk, :count)
  end

  @doc """
  Returns the count of chunks with embeddings.
  """
  def count_chunks_with_embeddings do
    from(cv in ChunkVector)
    |> Repo.aggregate(:count)
  end

  # Chunk Vectors

  @doc """
  Creates or updates a chunk vector.
  """
  def upsert_chunk_vector(chunk_id, embedding) do
    embedding_vector =
      case embedding do
        %Pgvector{} -> embedding
        list when is_list(list) -> Pgvector.new(list)
      end

    case Repo.get_by(ChunkVector, chunk_id: chunk_id) do
      nil ->
        %ChunkVector{}
        |> ChunkVector.changeset(%{chunk_id: chunk_id, embedding: embedding_vector})
        |> Repo.insert()

      existing ->
        existing
        |> ChunkVector.changeset(%{embedding: embedding_vector})
        |> Repo.update()
    end
  end

  @doc """
  Finds chunks similar to a query embedding.
  """
  def find_similar_chunks(query_embedding, opts \\ []) do
    ChunkVector.search(query_embedding, opts)
    |> Enum.map(& &1.chunk)
    |> Repo.preload(:document)
  end

  @doc """
  Returns chunks without embeddings.
  """
  def list_chunks_without_embeddings(opts \\ []) do
    limit = Keyword.get(opts, :limit, 100)

    from(c in Chunk,
      left_join: cv in ChunkVector,
      on: cv.chunk_id == c.id,
      where: is_nil(cv.id),
      limit: ^limit,
      preload: [:document]
    )
    |> Repo.all()
  end
end
