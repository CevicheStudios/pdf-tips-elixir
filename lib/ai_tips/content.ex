defmodule AiTips.Content do
  @moduledoc """
  The Content context for managing tips.
  """

  import Ecto.Query, warn: false
  alias AiTips.Repo
  alias AiTips.Content.Tip
  alias AiTips.Knowledge

  @doc """
  Returns the list of all tips.
  """
  def list_tips do
    Tip
    |> order_by([t], desc: t.inserted_at)
    |> preload(:chunk)
    |> Repo.all()
  end

  @doc """
  Returns the list of unposted tips (drafts).
  """
  def list_draft_tips do
    from(t in Tip,
      where: t.posted == false,
      order_by: [desc: t.inserted_at],
      preload: [:chunk]
    )
    |> Repo.all()
  end

  @doc """
  Returns the list of posted tips.
  """
  def list_posted_tips do
    from(t in Tip,
      where: t.posted == true,
      order_by: [desc: t.posted_at],
      preload: [:chunk]
    )
    |> Repo.all()
  end

  @doc """
  Returns the most recent tips.
  """
  def list_recent_tips(limit \\ 5) do
    from(t in Tip,
      order_by: [desc: t.inserted_at],
      limit: ^limit,
      preload: [:chunk]
    )
    |> Repo.all()
  end

  @doc """
  Gets a single tip.
  """
  def get_tip(id) do
    Tip
    |> Repo.get(id)
    |> Repo.preload(chunk: :document)
  end

  @doc """
  Creates a tip.
  """
  def create_tip(attrs \\ %{}) do
    %Tip{}
    |> Tip.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a tip.
  """
  def update_tip(%Tip{} = tip, attrs) do
    tip
    |> Tip.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a tip.
  """
  def delete_tip(%Tip{} = tip) do
    Repo.delete(tip)
  end

  @doc """
  Marks a tip as posted.
  """
  def mark_as_posted(%Tip{} = tip) do
    Repo.transaction(fn ->
      # Update the tip
      {:ok, updated_tip} =
        tip
        |> Tip.changeset(%{
          posted: true,
          posted_at: DateTime.utc_now() |> DateTime.truncate(:second)
        })
        |> Repo.update()

      # Mark the chunk as used if it exists
      if tip.chunk_id do
        case Knowledge.get_chunk(tip.chunk_id) do
          nil -> :ok
          chunk -> Knowledge.mark_chunk_as_used(chunk)
        end
      end

      updated_tip
    end)
  end

  @doc """
  Returns the count of all tips.
  """
  def count_tips do
    Repo.aggregate(Tip, :count)
  end

  @doc """
  Returns the count of draft tips.
  """
  def count_draft_tips do
    from(t in Tip, where: t.posted == false)
    |> Repo.aggregate(:count)
  end

  @doc """
  Returns the count of posted tips.
  """
  def count_posted_tips do
    from(t in Tip, where: t.posted == true)
    |> Repo.aggregate(:count)
  end
end
