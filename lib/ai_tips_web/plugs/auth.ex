defmodule AiTipsWeb.Plugs.Auth do
  @moduledoc """
  Authentication plugs for the application.
  """

  import Plug.Conn
  import Phoenix.Controller

  alias AiTips.Accounts
  alias AiTips.Accounts.User

  @doc """
  Fetches the current user from the session and assigns it to the conn.
  """
  def fetch_current_user(conn, _opts) do
    user_id = get_session(conn, :user_id)
    user = user_id && Accounts.get_user(user_id)
    assign(conn, :current_user, user)
  end

  @doc """
  Requires that a user is authenticated.
  Redirects to login if not authenticated.
  """
  def require_authenticated_user(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
    else
      conn
      |> put_flash(:error, "You must log in to access this page.")
      |> redirect(to: "/login")
      |> halt()
    end
  end

  @doc """
  Requires that the current user is an admin.
  Returns 403 if not an admin.
  """
  def require_admin_user(conn, _opts) do
    case conn.assigns[:current_user] do
      %User{role: "admin"} ->
        conn

      %User{} ->
        conn
        |> put_status(:forbidden)
        |> put_view(html: AiTipsWeb.ErrorHTML)
        |> render(:"403")
        |> halt()

      nil ->
        conn
        |> put_flash(:error, "You must log in to access this page.")
        |> redirect(to: "/login")
        |> halt()
    end
  end
end
