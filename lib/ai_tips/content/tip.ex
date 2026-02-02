defmodule AiTips.Content.Tip do
  use Ecto.Schema
  import Ecto.Changeset

  alias AiTips.Knowledge.Chunk

  schema "tips" do
    field :title, :string
    field :content, :string
    field :example, :string
    field :source_reference, :string
    field :hashtags, {:array, :string}, default: []
    field :posted, :boolean, default: false
    field :posted_at, :utc_datetime

    belongs_to :chunk, Chunk

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(tip, attrs) do
    tip
    |> cast(attrs, [:title, :content, :example, :source_reference, :hashtags, :posted, :posted_at, :chunk_id])
    |> validate_required([:title, :content])
    |> foreign_key_constraint(:chunk_id)
  end

  @doc """
  Generates a Microsoft Teams Adaptive Card message for the tip.
  """
  def teams_message(%__MODULE__{} = tip) do
    %{
      type: "message",
      attachments: [
        %{
          contentType: "application/vnd.microsoft.card.adaptive",
          contentUrl: nil,
          content: %{
            "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
            type: "AdaptiveCard",
            version: "1.4",
            body: [
              %{
                type: "TextBlock",
                text: "💡 AI Tip of the Day",
                weight: "bolder",
                size: "large",
                color: "accent"
              },
              %{
                type: "TextBlock",
                text: tip.title,
                weight: "bolder",
                size: "medium",
                wrap: true
              },
              %{
                type: "TextBlock",
                text: tip.content,
                wrap: true
              },
              %{
                type: "TextBlock",
                text: "**Example:**",
                weight: "bolder",
                spacing: "medium"
              },
              %{
                type: "TextBlock",
                text: tip.example || "See the tip above for guidance.",
                wrap: true,
                isSubtle: true
              },
              %{
                type: "TextBlock",
                text: format_hashtags(tip.hashtags),
                size: "small",
                color: "accent",
                spacing: "medium",
                wrap: true
              },
              %{
                type: "TextBlock",
                text: "📚 Source: #{tip.source_reference || "Unknown"}",
                size: "small",
                isSubtle: true,
                spacing: "small"
              }
            ]
          }
        }
      ]
    }
  end

  defp format_hashtags(nil), do: ""
  defp format_hashtags([]), do: ""
  defp format_hashtags(hashtags) when is_list(hashtags) do
    Enum.join(hashtags, "  ")
  end

  @doc """
  Generates a Markdown file content for the tip.
  """
  def to_markdown(%__MODULE__{} = tip) do
    """
    # #{tip.title}

    #{tip.content}

    ## Example

    #{tip.example || "_No example provided._"}

    ## Tags

    #{format_hashtags_markdown(tip.hashtags)}

    ---

    **Source:** #{tip.source_reference || "Unknown"}
    **Generated:** #{format_date(tip.inserted_at)}
    """
  end

  @doc """
  Generates a filename slug for the tip.
  """
  def to_filename(%__MODULE__{} = tip) do
    slug =
      tip.title
      |> String.downcase()
      |> String.replace(~r/[^a-z0-9\s-]/, "")
      |> String.replace(~r/\s+/, "-")
      |> String.slice(0, 50)

    "#{slug}-#{tip.id}.md"
  end

  @doc """
  Generates the payload for Power Automate HTTP trigger.
  Includes both Teams message and SharePoint file data.
  """
  def power_automate_payload(%__MODULE__{} = tip) do
    %{
      title: tip.title,
      content: tip.content,
      example: tip.example,
      source_reference: tip.source_reference,
      hashtags: tip.hashtags || [],
      markdown: to_markdown(tip),
      filename: to_filename(tip),
      teams_message: teams_message(tip)
    }
  end

  defp format_hashtags_markdown(nil), do: ""
  defp format_hashtags_markdown([]), do: "_No tags_"
  defp format_hashtags_markdown(hashtags) when is_list(hashtags) do
    Enum.join(hashtags, " ")
  end

  defp format_date(nil), do: "Unknown"
  defp format_date(datetime), do: Calendar.strftime(datetime, "%B %d, %Y")
end
