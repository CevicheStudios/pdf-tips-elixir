defmodule PdfTipsElixir.Services.EmbeddingService do
  @moduledoc """
  Service for generating embeddings using Voyage AI.
  """

  require Logger

  alias PdfTipsElixir.Settings
  alias PdfTipsElixir.Knowledge

  @voyage_api_url "https://api.voyageai.com/v1/embeddings"
  @embedding_model "voyage-3-lite"
  @dimensions 512
  @max_text_length 16_000
  @rate_limit_delay 100

  @doc """
  Generates an embedding for a single chunk and stores it.
  """
  def generate_for_chunk(chunk) do
    with {:ok, api_key} <- get_api_key(),
         {:ok, embedding} <- generate_embedding(api_key, chunk.content, "document") do
      Knowledge.upsert_chunk_vector(chunk.id, embedding)
    end
  end

  @doc """
  Generates embeddings for all chunks in a document.
  """
  def generate_for_document(document) do
    chunks = Knowledge.list_chunks_for_document(document.id)
    chunks_without_embeddings = Enum.filter(chunks, &is_nil(&1.chunk_vector))

    results =
      Enum.map(chunks_without_embeddings, fn chunk ->
        result = generate_for_chunk(chunk)
        Process.sleep(@rate_limit_delay)
        result
      end)

    errors = Enum.filter(results, &match?({:error, _}, &1))

    if Enum.empty?(errors) do
      {:ok, length(chunks_without_embeddings)}
    else
      {:error, "Failed to generate #{length(errors)} embeddings"}
    end
  end

  @doc """
  Generates embeddings for all chunks without embeddings.
  """
  def generate_all_embeddings do
    chunks = Knowledge.list_chunks_without_embeddings(limit: 1000)
    total = length(chunks)

    results =
      Enum.with_index(chunks, 1)
      |> Enum.map(fn {chunk, index} ->
        result = generate_for_chunk(chunk)

        case result do
          {:ok, _} ->
            Logger.info("Generated embedding #{index}/#{total}")

          {:error, reason} ->
            Logger.error("Failed to generate embedding for chunk #{chunk.id}: #{reason}")
        end

        Process.sleep(@rate_limit_delay)
        result
      end)

    errors = Enum.filter(results, &match?({:error, _}, &1))

    if Enum.empty?(errors) do
      {:ok, total}
    else
      {:error, "Failed to generate #{length(errors)} of #{total} embeddings"}
    end
  end

  @doc """
  Generates a query embedding for similarity search.
  """
  def generate_query_embedding(query) do
    with {:ok, api_key} <- get_api_key(),
         {:ok, embedding} <- generate_embedding(api_key, query, "query") do
      {:ok, embedding}
    end
  end

  @doc """
  Finds chunks similar to a query string.
  """
  def find_similar_chunks(query, opts \\ []) do
    limit = Keyword.get(opts, :limit, 5)
    exclude_used = Keyword.get(opts, :exclude_used, true)

    with {:ok, query_embedding} <- generate_query_embedding(query) do
      exclude_ids =
        if exclude_used do
          Knowledge.list_available_chunks(limit: 1000)
          |> Enum.filter(&(&1.times_used > 0))
          |> Enum.map(& &1.id)
        else
          []
        end

      chunks = Knowledge.find_similar_chunks(query_embedding, limit: limit, exclude_chunk_ids: exclude_ids)
      {:ok, chunks}
    end
  end

  @doc """
  Finds chunks similar to a given chunk.
  """
  def find_similar_to_chunk(chunk, opts \\ []) do
    limit = Keyword.get(opts, :limit, 5)

    case Knowledge.get_chunk(chunk.id) do
      %{chunk_vector: %{embedding: embedding}} when not is_nil(embedding) ->
        chunks = Knowledge.find_similar_chunks(embedding, limit: limit + 1, exclude_chunk_ids: [chunk.id])
        {:ok, Enum.take(chunks, limit)}

      _ ->
        {:error, "Chunk has no embedding"}
    end
  end

  @doc """
  Checks if the Voyage API is configured.
  """
  def configured? do
    Settings.voyage_configured?()
  end

  @doc """
  Checks if approaching the token limit.
  """
  def near_token_limit? do
    Settings.voyage_near_limit?()
  end

  @doc """
  Checks if over the token limit.
  """
  def over_token_limit? do
    Settings.voyage_over_limit?()
  end

  @doc """
  Returns token usage statistics.
  """
  def token_usage_stats do
    Settings.token_usage_stats()
  end

  # Private functions

  defp get_api_key do
    case Settings.effective_voyage_key() do
      nil -> {:error, "Voyage API key not configured"}
      key -> {:ok, key}
    end
  end

  defp generate_embedding(api_key, text, input_type) do
    truncated_text = String.slice(text, 0, @max_text_length)

    body = %{
      model: @embedding_model,
      input: truncated_text,
      input_type: input_type,
      output_dimension: @dimensions
    }

    case Req.post(@voyage_api_url,
           json: body,
           headers: [
             {"authorization", "Bearer #{api_key}"},
             {"content-type", "application/json"}
           ]
         ) do
      {:ok, %{status: 200, body: response}} ->
        embedding = get_in(response, ["data", Access.at(0), "embedding"])
        tokens_used = get_in(response, ["usage", "total_tokens"]) || estimate_tokens(truncated_text)
        track_token_usage(tokens_used)
        {:ok, embedding}

      {:ok, %{status: status, body: body}} ->
        Logger.error("Voyage AI error: #{status} - #{inspect(body)}")
        {:error, "Voyage API error: #{status}"}

      {:error, reason} ->
        Logger.error("Voyage AI request failed: #{inspect(reason)}")
        {:error, "Voyage API request failed: #{inspect(reason)}"}
    end
  end

  defp estimate_tokens(text) do
    # Rough estimate: ~4 characters per token for English
    ceil(String.length(text) / 4)
  end

  defp track_token_usage(tokens) do
    case Settings.add_voyage_tokens(tokens) do
      {:ok, _} -> :ok
      {:error, reason} -> Logger.error("Failed to track token usage: #{reason}")
    end
  end
end
