defmodule AiTips.Knowledge.Chunk do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias AiTips.Knowledge.{Document, ChunkVector}
  alias AiTips.Content.Tip

  @days_before_reuse 30

  schema "chunks" do
    field :content, :string
    field :page_number, :integer
    field :chunk_index, :integer
    field :times_used, :integer, default: 0
    field :last_used_at, :utc_datetime

    belongs_to :document, Document
    has_one :chunk_vector, ChunkVector
    has_many :tips, Tip

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(chunk, attrs) do
    chunk
    |> cast(attrs, [:content, :page_number, :chunk_index, :times_used, :last_used_at, :document_id])
    |> validate_required([:content, :chunk_index, :document_id])
    |> foreign_key_constraint(:document_id)
  end

  @doc """
  Returns a query for chunks available for tip generation.
  A chunk is available if it has never been used, or was last used more than 30 days ago.
  """
  def available_for_tips do
    cutoff = DateTime.utc_now() |> DateTime.add(-@days_before_reuse, :day)

    from c in __MODULE__,
      where: c.times_used == 0 or c.last_used_at < ^cutoff
  end

  @doc """
  Marks a chunk as used for tip generation.
  """
  def mark_as_used(chunk) do
    chunk
    |> change(%{
      times_used: chunk.times_used + 1,
      last_used_at: DateTime.utc_now() |> DateTime.truncate(:second)
    })
  end

  @doc """
  Returns a human-readable source label for the chunk.
  """
  def source_label(%__MODULE__{document: %Document{} = doc} = chunk) do
    case doc.source_type do
      "pdf" ->
        page = if chunk.page_number, do: " (Page #{chunk.page_number})", else: ""
        "#{doc.name}#{page}"

      "url" ->
        doc.name
    end
  end

  def source_label(%__MODULE__{document: nil}), do: "Unknown source"

  @doc """
  Checks if the chunk has an embedding.
  """
  def has_embedding?(%__MODULE__{chunk_vector: %ChunkVector{}}), do: true
  def has_embedding?(_), do: false
end
