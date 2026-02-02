defmodule AiTips.Services.TipGenerator do
  @moduledoc """
  Service for generating tips using Claude AI.
  """

  require Logger

  alias AiTips.Settings
  alias AiTips.Knowledge
  alias AiTips.Knowledge.Chunk
  alias AiTips.Content
  alias AiTips.Services.EmbeddingService

  @anthropic_api_url "https://api.anthropic.com/v1/messages"
  @model "claude-sonnet-4-20250514"
  @max_tokens 1200

  @system_prompt """
  You are an expert at creating concise, actionable productivity tips about AI and prompting.
  Your tips should be:
  - Bite-sized and easy to understand (2-3 sentences max for the main tip)
  - Practical and immediately actionable
  - Include a concrete example
  - Professional but engaging tone suitable for a Microsoft Teams channel

  Format your response as JSON with these fields:
  - title: A catchy, short title (max 60 chars)
  - content: The main tip explanation (2-3 sentences)
  - example: A concrete example showing the tip in action
  - hashtags: An array of 3-5 hashtags for filtering/searching in Teams. Make them specific and useful:
    - Include the main technique or concept (e.g., #ChainOfThought, #FewShotLearning)
    - Include the use case or domain (e.g., #CodeGeneration, #Writing, #DataAnalysis)
    - Include skill level if relevant (e.g., #Beginner, #Advanced)
    - Use PascalCase without spaces (e.g., #PromptEngineering not #prompt engineering)
  """

  @doc """
  Generates a tip from a specific chunk.
  """
  def generate_from_chunk(%Chunk{} = chunk) do
    chunk = chunk |> AiTips.Repo.preload(:document)

    with {:ok, api_key} <- get_api_key(),
         prompt <- build_prompt(chunk),
         {:ok, response} <- call_claude(api_key, prompt),
         {:ok, tip_data} <- parse_response(response, chunk) do
      {:ok, tip_data}
    end
  end

  @doc """
  Generates a tip and saves it to the database.

  ## Options
    * `:topic` - Optional topic for semantic search
    * `:document_id` - Optional document ID to restrict chunk selection
  """
  def generate_tip(opts \\ []) do
    with {:ok, chunk} <- select_chunk(opts),
         {:ok, tip_data} <- generate_from_chunk(chunk) do
      Content.create_tip(%{
        title: tip_data.title,
        content: tip_data.content,
        example: tip_data.example,
        hashtags: tip_data.hashtags || [],
        source_reference: Chunk.source_label(chunk),
        chunk_id: chunk.id
      })
    end
  end

  @doc """
  Checks if the Claude API is configured.
  """
  def configured? do
    Settings.anthropic_configured?()
  end

  # Private functions

  defp get_api_key do
    case Settings.effective_anthropic_key() do
      nil -> {:error, "Anthropic API key not configured"}
      key -> {:ok, key}
    end
  end

  defp select_chunk(opts) do
    topic = Keyword.get(opts, :topic)
    document_id = Keyword.get(opts, :document_id)

    cond do
      # If topic is provided and embeddings are configured, use semantic search
      topic && EmbeddingService.configured?() ->
        case EmbeddingService.find_similar_chunks(topic, limit: 5) do
          {:ok, []} ->
            # Fall back to random selection
            get_random_chunk(document_id)

          {:ok, chunks} ->
            chunks =
              if document_id do
                Enum.filter(chunks, &(&1.document_id == document_id))
              else
                chunks
              end

            case chunks do
              [chunk | _] -> {:ok, chunk}
              [] -> get_random_chunk(document_id)
            end

          {:error, _} ->
            get_random_chunk(document_id)
        end

      true ->
        get_random_chunk(document_id)
    end
  end

  defp get_random_chunk(document_id) do
    case Knowledge.get_random_available_chunk(document_id: document_id) do
      nil -> {:error, "No available chunks for tip generation"}
      chunk -> {:ok, chunk}
    end
  end

  defp build_prompt(%Chunk{} = chunk) do
    page_info = if chunk.page_number, do: " (Page #{chunk.page_number})", else: ""

    """
    Based on the following content from "#{chunk.document.name}"#{page_info},
    create a "Tip of the Day" about AI or prompting techniques.

    Source content:
    ---
    #{chunk.content}
    ---

    Generate a tip based on the key insight from this content.
    """
  end

  defp call_claude(api_key, prompt) do
    body = %{
      model: @model,
      max_tokens: @max_tokens,
      system: @system_prompt,
      messages: [
        %{role: "user", content: prompt}
      ]
    }

    case Req.post(@anthropic_api_url,
           json: body,
           headers: [
             {"x-api-key", api_key},
             {"anthropic-version", "2023-06-01"},
             {"content-type", "application/json"}
           ]
         ) do
      {:ok, %{status: 200, body: response}} ->
        text = get_in(response, ["content", Access.at(0), "text"])
        {:ok, text}

      {:ok, %{status: status, body: body}} ->
        Logger.error("Anthropic API error: #{status} - #{inspect(body)}")
        {:error, "Anthropic API error: #{status}"}

      {:error, reason} ->
        Logger.error("Anthropic API request failed: #{inspect(reason)}")
        {:error, "Anthropic API request failed: #{inspect(reason)}"}
    end
  end

  defp parse_response(nil, _chunk), do: {:error, "Empty response from Claude"}

  defp parse_response(response, chunk) do
    # Strip markdown code blocks if present
    cleaned_response = response
    |> String.replace(~r/```json\s*/, "")
    |> String.replace(~r/```\s*$/, "")
    |> String.trim()

    # Try to extract JSON from the response
    case Regex.run(~r/\{[\s\S]*\}/, cleaned_response) do
      [json_str] ->
        case Jason.decode(json_str) do
          {:ok, data} ->
            {:ok, %{
              title: data["title"],
              content: data["content"],
              example: data["example"],
              hashtags: normalize_hashtags(data["hashtags"])
            }}

          {:error, decode_error} ->
            Logger.warning("JSON decode failed: #{inspect(decode_error)}, raw JSON: #{String.slice(json_str, 0, 200)}...")
            # Fall back to using the raw response
            fallback_tip(response, chunk)
        end

      nil ->
        fallback_tip(response, chunk)
    end
  end

  defp normalize_hashtags(nil), do: []
  defp normalize_hashtags(hashtags) when is_list(hashtags) do
    Enum.map(hashtags, fn tag ->
      tag = String.trim(tag)
      if String.starts_with?(tag, "#"), do: tag, else: "##{tag}"
    end)
  end
  defp normalize_hashtags(_), do: []

  defp fallback_tip(response, chunk) do
    {:ok, %{
      title: "AI Tip from #{chunk.document.name}",
      content: String.slice(response, 0, 500),
      example: "See the original source for more details.",
      hashtags: ["#AITip", "#Productivity"]
    }}
  end
end
