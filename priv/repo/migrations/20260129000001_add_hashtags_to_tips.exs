defmodule PdfTipsElixir.Repo.Migrations.AddHashtagsToTips do
  use Ecto.Migration

  def change do
    alter table(:tips) do
      add :hashtags, {:array, :string}, default: []
    end
  end
end
