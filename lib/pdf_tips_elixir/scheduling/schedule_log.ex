defmodule PdfTipsElixir.Scheduling.ScheduleLog do
  use Ecto.Schema
  import Ecto.Changeset

  alias PdfTipsElixir.Content.Tip

  @statuses ~w(success error skipped)

  schema "schedule_logs" do
    field :status, :string
    field :message, :string

    belongs_to :tip, Tip

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(schedule_log, attrs) do
    schedule_log
    |> cast(attrs, [:status, :message, :tip_id])
    |> validate_required([:status])
    |> validate_inclusion(:status, @statuses)
    |> foreign_key_constraint(:tip_id)
  end
end
