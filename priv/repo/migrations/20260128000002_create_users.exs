defmodule PdfTipsElixir.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :azure_uid, :string, null: false
      add :email, :string, null: false
      add :name, :string
      add :role, :string, default: "contributor", null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:users, [:azure_uid])
    create unique_index(:users, [:email])
  end
end
