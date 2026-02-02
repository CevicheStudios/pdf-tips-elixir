defmodule AiTips.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  @allowed_domain "xogo.io"

  schema "users" do
    field :azure_uid, :string
    field :email, :string
    field :name, :string
    field :role, :string, default: "contributor"

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:azure_uid, :email, :name, :role])
    |> validate_required([:azure_uid, :email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_domain()
    |> validate_inclusion(:role, ["admin", "contributor"])
    |> unique_constraint(:azure_uid)
    |> unique_constraint(:email)
  end

  defp validate_domain(changeset) do
    case get_change(changeset, :email) do
      nil ->
        changeset

      email ->
        if String.ends_with?(email, "@#{@allowed_domain}") do
          changeset
        else
          add_error(changeset, :email, "must be a @#{@allowed_domain} email")
        end
    end
  end

  def admin?(%__MODULE__{role: "admin"}), do: true
  def admin?(_), do: false
end
