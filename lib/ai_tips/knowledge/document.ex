defmodule AiTips.Knowledge.Document do
  use Ecto.Schema
  import Ecto.Changeset

  alias AiTips.Knowledge.Chunk

  schema "documents" do
    field :name, :string
    field :file_path, :string
    field :content, :string
    field :page_count, :integer
    field :processed, :boolean, default: false
    field :source_type, :string, default: "pdf"
    field :source_url, :string

    has_many :chunks, Chunk

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(document, attrs) do
    document
    |> cast(attrs, [:name, :file_path, :content, :page_count, :processed, :source_type, :source_url])
    |> validate_required([:name])
    |> validate_inclusion(:source_type, ["pdf", "url"])
    |> validate_source()
  end

  defp validate_source(changeset) do
    source_type = get_field(changeset, :source_type)

    case source_type do
      "pdf" ->
        validate_required(changeset, [:file_path])

      "url" ->
        changeset
        |> validate_required([:source_url])
        |> validate_url()

      _ ->
        changeset
    end
  end

  defp validate_url(changeset) do
    case get_change(changeset, :source_url) do
      nil ->
        changeset

      url ->
        uri = URI.parse(url)

        if uri.scheme in ["http", "https"] and uri.host do
          changeset
        else
          add_error(changeset, :source_url, "must be a valid HTTP(S) URL")
        end
    end
  end

  def pdf?(%__MODULE__{source_type: "pdf"}), do: true
  def pdf?(_), do: false

  def url?(%__MODULE__{source_type: "url"}), do: true
  def url?(_), do: false
end
