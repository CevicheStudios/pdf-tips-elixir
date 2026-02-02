defmodule AiTips.Workers.GenerateEmbeddingsWorker do
  @moduledoc """
  Oban worker for generating embeddings for chunks in the background.
  """

  use Oban.Worker,
    queue: :embeddings,
    max_attempts: 3

  require Logger

  alias AiTips.Services.EmbeddingService

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"document_id" => document_id}}) do
    Logger.info("Generating embeddings for document #{document_id}")

    unless EmbeddingService.configured?() do
      Logger.warning("Embedding generation skipped: Voyage API not configured")
      return_ok()
    end

    document = AiTips.Knowledge.get_document(document_id)

    if document do
      case EmbeddingService.generate_for_document(document) do
        {:ok, count} ->
          Logger.info("Generated #{count} embeddings for document #{document_id}")
          :ok

        {:error, reason} ->
          Logger.error("Embedding generation failed for document #{document_id}: #{reason}")
          {:error, reason}
      end
    else
      Logger.warning("Document #{document_id} not found")
      :ok
    end
  end

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"all" => true}}) do
    Logger.info("Generating all missing embeddings")

    unless EmbeddingService.configured?() do
      Logger.warning("Embedding generation skipped: Voyage API not configured")
      return_ok()
    end

    case EmbeddingService.generate_all_embeddings() do
      {:ok, count} ->
        Logger.info("Generated #{count} embeddings")
        :ok

      {:error, reason} ->
        Logger.error("Embedding generation failed: #{reason}")
        {:error, reason}
    end
  end

  defp return_ok, do: :ok

  @doc """
  Enqueues a job to generate embeddings for a document.
  """
  def enqueue_for_document(document_id) do
    %{document_id: document_id}
    |> new()
    |> Oban.insert()
  end

  @doc """
  Enqueues a job to generate all missing embeddings.
  """
  def enqueue_all do
    %{all: true}
    |> new()
    |> Oban.insert()
  end
end
