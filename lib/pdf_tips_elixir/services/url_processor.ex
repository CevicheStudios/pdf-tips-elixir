defmodule PdfTipsElixir.Services.UrlProcessor do
  @moduledoc """
  Service for processing web URLs.
  Uses Req for HTTP and Floki for HTML parsing.
  """

  require Logger

  alias PdfTipsElixir.Knowledge
  alias PdfTipsElixir.Knowledge.Document

  @chunk_size 1000
  @chunk_overlap 200
  @min_chunk_length 50

  # Elements to remove (navigation, ads, etc.)
  @remove_selectors [
    "script", "style", "noscript", "iframe",
    "nav", "header", "footer", "aside",
    ".nav", ".navbar", ".navigation", ".menu",
    ".header", ".footer", ".sidebar",
    ".advertisement", ".ad", ".ads",
    ".cookie-banner", ".popup",
    "#nav", "#header", "#footer", "#sidebar"
  ]

  # Elements likely to contain main content
  @content_selectors [
    "article", "main", ".content", ".post", ".entry",
    ".article-content", ".post-content", ".entry-content",
    "[role=main]", "[role=article]"
  ]

  @doc """
  Processes a URL document: fetches content, extracts text, creates chunks.
  """
  def process!(%Document{processed: true} = document), do: {:ok, document}

  def process!(%Document{source_type: "url", source_url: url} = document) when is_binary(url) do
    with {:ok, html} <- fetch_url(url),
         {:ok, text} <- extract_text(html),
         {:ok, updated_doc} <- Knowledge.update_document(document, %{
           content: text,
           processed: true
         }),
         :ok <- create_chunks(updated_doc.id, text) do
      {:ok, updated_doc}
    end
  end

  def process!(%Document{}), do: {:error, "Document is not a URL or has no source_url"}

  @doc """
  Fetches HTML content from a URL.
  """
  def fetch_url(url) do
    case Req.get(url,
           headers: [{"user-agent", "Mozilla/5.0 (compatible; PDFTipsBot/1.0)"}],
           receive_timeout: 30_000,
           connect_options: [timeout: 10_000]
         ) do
      {:ok, %{status: status, body: body}} when status in 200..299 ->
        {:ok, body}

      {:ok, %{status: status}} ->
        {:error, "HTTP error: #{status}"}

      {:error, reason} ->
        Logger.error("URL fetch error: #{inspect(reason)}")
        {:error, "Failed to fetch URL: #{inspect(reason)}"}
    end
  end

  @doc """
  Extracts readable text from HTML content.
  """
  def extract_text(html) when is_binary(html) do
    case Floki.parse_document(html) do
      {:ok, document} ->
        # Remove unwanted elements
        cleaned = Enum.reduce(@remove_selectors, document, fn selector, doc ->
          Floki.filter_out(doc, selector)
        end)

        # Try to find main content area
        content = find_main_content(cleaned)

        # Extract text
        text = extract_text_from_element(content)
        clean_text = clean_whitespace(text)

        if String.length(clean_text) > 0 do
          {:ok, clean_text}
        else
          {:error, "No readable content found"}
        end

      {:error, reason} ->
        {:error, "Failed to parse HTML: #{inspect(reason)}"}
    end
  end

  defp find_main_content(document) do
    Enum.find_value(@content_selectors, document, fn selector ->
      case Floki.find(document, selector) do
        [] -> nil
        [element | _] -> element
      end
    end)
  end

  defp extract_text_from_element(element) when is_tuple(element) do
    Floki.traverse_and_update(element, fn
      {tag, attrs, children} when tag in ~w(p div section article) ->
        text = children |> Enum.map(&extract_text_from_element/1) |> Enum.join(" ")
        {tag, attrs, [text <> "\n\n"]}

      {tag, attrs, children} when tag in ~w(h1 h2 h3 h4 h5 h6) ->
        text = Floki.text({tag, attrs, children})
        {tag, attrs, ["\n\n" <> text <> "\n\n"]}

      {"li", attrs, children} ->
        text = Floki.text({"li", attrs, children})
        {"li", attrs, ["• " <> text <> "\n"]}

      {"br", attrs, _children} ->
        {"br", attrs, ["\n"]}

      other ->
        other
    end)
    |> Floki.text()
  end

  defp extract_text_from_element(text) when is_binary(text), do: text
  defp extract_text_from_element(list) when is_list(list) do
    Enum.map(list, &extract_text_from_element/1) |> Enum.join(" ")
  end

  defp clean_whitespace(text) do
    text
    |> String.replace(~r/\s+/, " ")
    |> String.replace(~r/\n\s*\n\s*\n+/, "\n\n")
    |> String.trim()
  end

  defp create_chunks(document_id, text) do
    chunks_data =
      split_into_chunks(text)
      |> Enum.filter(fn text -> String.length(String.trim(text)) >= @min_chunk_length end)
      |> Enum.with_index()
      |> Enum.map(fn {chunk_text, index} ->
        %{
          content: String.trim(chunk_text),
          page_number: nil,
          chunk_index: index
        }
      end)

    Knowledge.create_chunks(document_id, chunks_data)
    :ok
  end

  @doc """
  Splits text into chunks with overlap.
  """
  def split_into_chunks(text) when is_binary(text) do
    text = String.trim(text)

    if String.length(text) == 0 do
      []
    else
      do_split_chunks(text, 0, [])
    end
  end

  defp do_split_chunks(text, start_pos, chunks) do
    text_length = String.length(text)

    if start_pos >= text_length do
      Enum.reverse(chunks)
    else
      end_pos = min(start_pos + @chunk_size, text_length)

      # Find a good break point
      end_pos =
        if end_pos < text_length do
          find_break_point(text, start_pos, end_pos)
        else
          end_pos
        end

      chunk = String.slice(text, start_pos, end_pos - start_pos)
      next_start = max(end_pos - @chunk_overlap, start_pos + 1)

      if next_start <= start_pos do
        Enum.reverse([chunk | chunks])
      else
        do_split_chunks(text, next_start, [chunk | chunks])
      end
    end
  end

  defp find_break_point(text, start_pos, end_pos) do
    chunk = String.slice(text, start_pos, end_pos - start_pos)

    # Look for paragraph, sentence, or word boundary
    cond do
      break = find_last_match(chunk, ~r/\n\n/) ->
        start_pos + break + 2

      break = find_last_match(chunk, ~r/[.!?]\s/) ->
        start_pos + break + 1

      break = find_last_match(chunk, ~r/\s/) ->
        start_pos + break + 1

      true ->
        end_pos
    end
  end

  defp find_last_match(text, regex) do
    case Regex.scan(regex, text, return: :index) do
      [] -> nil
      matches ->
        {offset, _} = List.last(matches) |> List.first()
        # Only use if in second half of chunk
        if offset > div(String.length(text), 2), do: offset, else: nil
    end
  end
end
