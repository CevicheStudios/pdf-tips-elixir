defmodule PdfTipsElixirWeb.UserAuth do
  @moduledoc """
  LiveView authentication helpers.
  """

  import Phoenix.LiveView
  import Phoenix.Component

  alias PdfTipsElixir.Accounts
  alias PdfTipsElixir.Accounts.User

  # Ensures user is authenticated
  def on_mount(:ensure_authenticated, _params, session, socket) do
    socket = mount_current_user(socket, session)

    if socket.assigns.current_user do
      {:cont, socket}
    else
      socket =
        socket
        |> put_flash(:error, "You must log in to access this page.")
        |> redirect(to: "/login")

      {:halt, socket}
    end
  end

  # Ensures user is an admin
  def on_mount(:ensure_admin, _params, session, socket) do
    socket = mount_current_user(socket, session)

    case socket.assigns.current_user do
      %User{role: "admin"} ->
        {:cont, socket}

      %User{} ->
        socket =
          socket
          |> put_flash(:error, "You don't have permission to access this page.")
          |> redirect(to: "/")

        {:halt, socket}

      nil ->
        socket =
          socket
          |> put_flash(:error, "You must log in to access this page.")
          |> redirect(to: "/login")

        {:halt, socket}
    end
  end

  # Mounts current user for routes that allow both auth and non-auth users
  def on_mount(:mount_current_user, _params, session, socket) do
    {:cont, mount_current_user(socket, session)}
  end

  defp mount_current_user(socket, session) do
    case session do
      %{"user_id" => user_id} ->
        assign_new(socket, :current_user, fn -> Accounts.get_user(user_id) end)

      _ ->
        assign_new(socket, :current_user, fn -> nil end)
    end
  end
end
