defmodule PdfTipsElixir.Services.PdfProcessor do
  @moduledoc """
  Service for processing PDF documents.
  Uses pdftotext (from poppler-utils) to extract text.
  """

  require Logger

  alias PdfTipsElixir.Knowledge
  alias PdfTipsElixir.Knowledge.Document

  @chunk_size 1000
  @chunk_overlap 200
  @min_chunk_length 50

  @doc """
  Processes a PDF document: extracts text, creates chunks.
  """
  def process!(%Document{processed: true} = document), do: {:ok, document}

  def process!(%Document{source_type: "pdf", file_path: file_path} = document) when is_binary(file_path) do
    with {:ok, text_by_page} <- extract_text(file_path),
         full_content = text_by_page |> Map.values() |> Enum.join("\n\n"),
         page_count = text_by_page |> Map.keys() |> Enum.max(fn -> 0 end),
         {:ok, updated_doc} <- Knowledge.update_document(document, %{
           content: full_content,
           page_count: page_count,
           processed: true
         }),
         :ok <- create_chunks(updated_doc.id, text_by_page) do
      {:ok, updated_doc}
    end
  end

  def process!(%Document{}), do: {:error, "Document is not a PDF or has no file path"}

  @doc """
  Extracts text from a PDF file using pdftotext.
  Returns a map of page_number => text.
  """
  def extract_text(file_path) do
    # Check if pdftotext is available
    case System.find_executable("pdftotext") do
      nil ->
        {:error, "pdftotext not found. Please install poppler-utils."}

      pdftotext_path ->
        extract_with_pdftotext(pdftotext_path, file_path)
    end
  end

  defp extract_with_pdftotext(pdftotext_path, file_path) do
    # First, get the page count
    case System.cmd("pdfinfo", [file_path], stderr_to_stdout: true) do
      {output, 0} ->
        page_count = parse_page_count(output)
        extract_pages(pdftotext_path, file_path, page_count)

      {error, _} ->
        Logger.error("pdfinfo failed: #{error}")
        # Fall back to extracting all at once
        extract_all_pages(pdftotext_path, file_path)
    end
  end

  defp parse_page_count(output) do
    case Regex.run(~r/Pages:\s+(\d+)/, output) do
      [_, count] -> String.to_integer(count)
      _ -> 1
    end
  end

  defp extract_pages(pdftotext_path, file_path, page_count) do
    text_by_page =
      1..page_count
      |> Enum.reduce(%{}, fn page, acc ->
        case System.cmd(pdftotext_path, ["-f", "#{page}", "-l", "#{page}", "-layout", file_path, "-"], stderr_to_stdout: true) do
          {text, 0} ->
            Map.put(acc, page, String.trim(text))

          {error, _} ->
            Logger.warning("Failed to extract page #{page}: #{error}")
            acc
        end
      end)

    if map_size(text_by_page) > 0 do
      {:ok, text_by_page}
    else
      {:error, "Failed to extract any text from PDF"}
    end
  end

  defp extract_all_pages(pdftotext_path, file_path) do
    case System.cmd(pdftotext_path, ["-layout", file_path, "-"], stderr_to_stdout: true) do
      {text, 0} ->
        {:ok, %{1 => String.trim(text)}}

      {error, _} ->
        {:error, "Failed to extract text from PDF: #{error}"}
    end
  end

  defp create_chunks(document_id, text_by_page) do
    chunks_data =
      text_by_page
      |> Enum.flat_map(fn {page_number, page_text} ->
        split_into_chunks(page_text)
        |> Enum.map(fn chunk_text -> {page_number, chunk_text} end)
      end)
      |> Enum.filter(fn {_, text} -> String.length(String.trim(text)) >= @min_chunk_length end)
      |> Enum.with_index()
      |> Enum.map(fn {{page_number, text}, index} ->
        %{
          content: String.trim(text),
          page_number: page_number,
          chunk_index: index
        }
      end)

    Knowledge.create_chunks(document_id, chunks_data)
    :ok
  end

  @doc """
  Splits text into chunks with overlap.
  Tries to break at sentence boundaries when possible.
  """
  def split_into_chunks(text) when is_binary(text) do
    text = String.trim(text)

    if String.length(text) == 0 do
      []
    else
      do_split_chunks(text, 0, [])
    end
  end

  defp do_split_chunks(text, start_pos, chunks) when start_pos >= byte_size(text) do
    Enum.reverse(chunks)
  end

  defp do_split_chunks(text, start_pos, chunks) do
    text_length = String.length(text)
    end_pos = min(start_pos + @chunk_size, text_length)

    # Try to break at sentence boundary if not at the end
    end_pos =
      if end_pos < text_length do
        find_sentence_boundary(text, start_pos, end_pos)
      else
        end_pos
      end

    chunk = String.slice(text, start_pos, end_pos - start_pos)
    next_start = max(end_pos - @chunk_overlap, start_pos + 1)

    # Prevent infinite loop
    if next_start <= start_pos do
      Enum.reverse([chunk | chunks])
    else
      do_split_chunks(text, next_start, [chunk | chunks])
    end
  end

  defp find_sentence_boundary(text, start_pos, end_pos) do
    # Look for sentence ending within the last 100 chars of chunk
    search_start = max(end_pos - 100, start_pos)
    search_text = String.slice(text, search_start, end_pos - search_start)

    case Regex.scan(~r/[.!?]\s/, search_text, return: :index) do
      [] ->
        end_pos

      matches ->
        # Get the last match
        {offset, _length} = List.last(matches) |> List.first()
        search_start + offset + 1
    end
  end
end
