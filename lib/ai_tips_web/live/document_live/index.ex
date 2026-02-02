defmodule AiTipsWeb.DocumentLive.Index do
  use AiTipsWeb, :live_view

  alias AiTips.Knowledge
  alias AiTips.Services.{PdfProcessor, UrlProcessor, EmbeddingService}

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Documents")
     |> assign(:documents, Knowledge.list_documents())
     |> assign(:url_form, to_form(%{"url" => "", "name" => ""}))
     |> assign(:processing, false)
     |> allow_upload(:pdf,
       accept: ~w(.pdf),
       max_entries: 1,
       max_file_size: 50_000_000
     )}
  end

  @impl true
  def handle_event("validate_pdf", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("upload_pdf", _params, socket) do
    [_entry] = socket.assigns.uploads.pdf.entries

    socket =
      consume_uploaded_entries(socket, :pdf, fn %{path: path}, entry ->
        uploads_dir = Path.join([:code.priv_dir(:ai_tips), "static", "uploads"])
        File.mkdir_p!(uploads_dir)
        filename = "#{System.unique_integer([:positive])}_#{entry.client_name}"
        dest = Path.join(uploads_dir, filename)
        File.cp!(path, dest)
        {:ok, %{path: dest, name: entry.client_name}}
      end)
      |> case do
        [%{path: path, name: name}] ->
          case Knowledge.create_document(%{name: name, file_path: path, source_type: "pdf"}) do
            {:ok, document} ->
              socket
              |> assign(:processing, true)
              |> start_async(:process_pdf, fn ->
                with {:ok, doc} <- PdfProcessor.process!(document) do
                  if EmbeddingService.configured?(), do: EmbeddingService.generate_for_document(doc)
                  {:ok, doc}
                end
              end)

            {:error, changeset} ->
              put_flash(socket, :error, "Failed to create document: #{inspect(changeset.errors)}")
          end

        _ ->
          put_flash(socket, :error, "Upload failed")
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("validate_url", %{"url" => url, "name" => name}, socket) do
    {:noreply, assign(socket, :url_form, to_form(%{"url" => url, "name" => name}))}
  end

  @impl true
  def handle_event("add_url", %{"url" => url, "name" => name}, socket) do
    name = if name == "", do: extract_title_from_url(url), else: name

    case Knowledge.create_document(%{name: name, source_type: "url", source_url: url}) do
      {:ok, document} ->
        socket =
          socket
          |> assign(:processing, true)
          |> assign(:url_form, to_form(%{"url" => "", "name" => ""}))
          |> start_async(:process_url, fn ->
            with {:ok, doc} <- UrlProcessor.process!(document) do
              if EmbeddingService.configured?(), do: EmbeddingService.generate_for_document(doc)
              {:ok, doc}
            end
          end)

        {:noreply, socket}

      {:error, changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to create document: #{inspect(changeset.errors)}")}
    end
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    document = Knowledge.get_document(id)

    case Knowledge.delete_document(document) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Document deleted")
         |> assign(:documents, Knowledge.list_documents())}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to delete document")}
    end
  end

  @impl true
  def handle_async(:process_pdf, {:ok, {:ok, _doc}}, socket) do
    {:noreply,
     socket
     |> assign(:processing, false)
     |> assign(:documents, Knowledge.list_documents())
     |> put_flash(:info, "PDF processed successfully")}
  end

  @impl true
  def handle_async(:process_pdf, {:ok, {:error, reason}}, socket) do
    {:noreply,
     socket
     |> assign(:processing, false)
     |> put_flash(:error, "Failed to process PDF: #{reason}")}
  end

  @impl true
  def handle_async(:process_pdf, {:exit, reason}, socket) do
    {:noreply,
     socket
     |> assign(:processing, false)
     |> put_flash(:error, "PDF processing failed: #{inspect(reason)}")}
  end

  @impl true
  def handle_async(:process_url, {:ok, {:ok, _doc}}, socket) do
    {:noreply,
     socket
     |> assign(:processing, false)
     |> assign(:documents, Knowledge.list_documents())
     |> put_flash(:info, "URL processed successfully")}
  end

  @impl true
  def handle_async(:process_url, {:ok, {:error, reason}}, socket) do
    {:noreply,
     socket
     |> assign(:processing, false)
     |> put_flash(:error, "Failed to process URL: #{reason}")}
  end

  @impl true
  def handle_async(:process_url, {:exit, reason}, socket) do
    {:noreply,
     socket
     |> assign(:processing, false)
     |> put_flash(:error, "URL processing failed: #{inspect(reason)}")}
  end

  defp extract_title_from_url(url) do
    uri = URI.parse(url)
    path = uri.path || ""
    case Path.basename(path) do
      "" -> uri.host || "Web Page"
      name -> name
    end
  end
end
