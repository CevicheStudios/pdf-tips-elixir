defmodule PdfTipsElixirWeb.TipLive.Show do
  use PdfTipsElixirWeb, :live_view

  alias PdfTipsElixir.Content
  alias PdfTipsElixir.Content.Tip
  alias PdfTipsElixir.Services.TeamsService

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    case Content.get_tip(id) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "Tip not found")
         |> redirect(to: ~p"/tips")}

      tip ->
        {:ok,
         assign(socket,
           page_title: tip.title,
           tip: tip,
           posting: false,
           teams_preview: Jason.encode!(Tip.teams_message(tip), pretty: true)
         )}
    end
  end

  @impl true
  def handle_event("post_to_teams", _params, socket) do
    tip = socket.assigns.tip

    socket =
      socket
      |> assign(:posting, true)
      |> start_async(:post_to_teams, fn -> TeamsService.post_tip(tip) end)

    {:noreply, socket}
  end

  @impl true
  def handle_event("delete", _params, socket) do
    case Content.delete_tip(socket.assigns.tip) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Tip deleted")
         |> redirect(to: ~p"/tips")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to delete tip")}
    end
  end

  @impl true
  def handle_async(:post_to_teams, {:ok, {:ok, tip}}, socket) do
    {:noreply,
     socket
     |> assign(:posting, false)
     |> assign(:tip, tip)
     |> put_flash(:info, "Tip posted to Teams successfully")}
  end

  @impl true
  def handle_async(:post_to_teams, {:ok, {:error, reason}}, socket) do
    {:noreply,
     socket
     |> assign(:posting, false)
     |> put_flash(:error, "Failed to post to Teams: #{reason}")}
  end

  @impl true
  def handle_async(:post_to_teams, {:exit, reason}, socket) do
    {:noreply,
     socket
     |> assign(:posting, false)
     |> put_flash(:error, "Teams posting failed: #{inspect(reason)}")}
  end

  defp format_datetime(nil), do: "Unknown"
  defp format_datetime(datetime), do: Calendar.strftime(datetime, "%b %d, %Y at %I:%M %p")
end
