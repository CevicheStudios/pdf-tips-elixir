defmodule AiTipsWeb.DocumentLive.Show do
  use AiTipsWeb, :live_view

  alias AiTips.Knowledge
  alias AiTips.Services.{EmbeddingService, TipGenerator}

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    case Knowledge.get_document_with_chunks(id) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "Document not found")
         |> redirect(to: ~p"/documents")}

      document ->
        chunks = Knowledge.list_chunks_for_document(document.id)
        embeddings_count = Enum.count(chunks, & &1.chunk_vector)

        {:ok,
         assign(socket,
           page_title: document.name,
           document: document,
           chunks: chunks,
           embeddings_count: embeddings_count,
           generating_embeddings: false,
           generating_tip: false
         )}
    end
  end

  @impl true
  def handle_event("generate_embeddings", _params, socket) do
    document = socket.assigns.document

    socket =
      socket
      |> assign(:generating_embeddings, true)
      |> start_async(:generate_embeddings, fn ->
        EmbeddingService.generate_for_document(document)
      end)

    {:noreply, socket}
  end

  @impl true
  def handle_event("generate_tip", _params, socket) do
    document_id = socket.assigns.document.id

    socket =
      socket
      |> assign(:generating_tip, true)
      |> start_async(:generate_tip, fn ->
        TipGenerator.generate_tip(document_id: document_id)
      end)

    {:noreply, socket}
  end

  @impl true
  def handle_async(:generate_embeddings, {:ok, {:ok, count}}, socket) do
    chunks = Knowledge.list_chunks_for_document(socket.assigns.document.id)
    embeddings_count = Enum.count(chunks, & &1.chunk_vector)

    {:noreply,
     socket
     |> assign(:generating_embeddings, false)
     |> assign(:chunks, chunks)
     |> assign(:embeddings_count, embeddings_count)
     |> put_flash(:info, "Generated #{count} embeddings")}
  end

  @impl true
  def handle_async(:generate_embeddings, {:ok, {:error, reason}}, socket) do
    {:noreply,
     socket
     |> assign(:generating_embeddings, false)
     |> put_flash(:error, "Failed to generate embeddings: #{reason}")}
  end

  @impl true
  def handle_async(:generate_embeddings, {:exit, reason}, socket) do
    {:noreply,
     socket
     |> assign(:generating_embeddings, false)
     |> put_flash(:error, "Embedding generation failed: #{inspect(reason)}")}
  end

  @impl true
  def handle_async(:generate_tip, {:ok, {:ok, tip}}, socket) do
    {:noreply,
     socket
     |> assign(:generating_tip, false)
     |> put_flash(:info, "Generated tip: #{tip.title}")
     |> redirect(to: ~p"/tips/#{tip.id}")}
  end

  @impl true
  def handle_async(:generate_tip, {:ok, {:error, reason}}, socket) do
    {:noreply,
     socket
     |> assign(:generating_tip, false)
     |> put_flash(:error, "Failed to generate tip: #{reason}")}
  end

  @impl true
  def handle_async(:generate_tip, {:exit, reason}, socket) do
    {:noreply,
     socket
     |> assign(:generating_tip, false)
     |> put_flash(:error, "Tip generation failed: #{inspect(reason)}")}
  end
end
