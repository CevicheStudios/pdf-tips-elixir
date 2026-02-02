defmodule AiTips.Accounts do
  @moduledoc """
  The Accounts context for user management.
  """

  import Ecto.Query, warn: false
  alias AiTips.Repo
  alias AiTips.Accounts.User

  @doc """
  Gets a user by id.
  """
  def get_user(id), do: Repo.get(User, id)

  @doc """
  Gets a user by Azure UID.
  """
  def get_user_by_azure_uid(azure_uid) do
    Repo.get_by(User, azure_uid: azure_uid)
  end

  @doc """
  Gets a user by email.
  """
  def get_user_by_email(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  Creates or updates a user from Azure AD authentication.
  First user is automatically made an admin.
  """
  def upsert_from_azure_ad(attrs) do
    case get_user_by_azure_uid(attrs.azure_uid) do
      nil -> create_user(attrs)
      user -> update_user(user, attrs)
    end
  end

  @doc """
  Creates a user.
  First user is automatically made an admin.
  """
  def create_user(attrs) do
    attrs = maybe_make_admin(attrs)

    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a user.
  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a user.
  """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  @doc """
  Returns the list of all users.
  """
  def list_users do
    Repo.all(from u in User, order_by: [asc: u.name])
  end

  @doc """
  Returns the count of users.
  """
  def count_users do
    Repo.aggregate(User, :count)
  end

  # First user is automatically an admin
  defp maybe_make_admin(attrs) do
    if count_users() == 0 do
      Map.put(attrs, :role, "admin")
    else
      attrs
    end
  end
end
