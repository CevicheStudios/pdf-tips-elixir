defmodule AiTipsWeb.DashboardLive do
  use AiTipsWeb, :live_view

  alias AiTips.Knowledge
  alias AiTips.Content
  alias AiTips.Services.{TipGenerator, TeamsService, EmbeddingService}

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(AiTips.PubSub, "dashboard")
    end

    {:ok, socket |> assign(:page_title, "Dashboard") |> assign_stats()}
  end

  @impl true
  def handle_event("generate_tip", _params, socket) do
    socket =
      socket
      |> assign(:generating, true)
      |> start_async(:generate_tip, fn -> TipGenerator.generate_tip() end)

    {:noreply, socket}
  end

  @impl true
  def handle_async(:generate_tip, {:ok, {:ok, tip}}, socket) do
    socket =
      socket
      |> assign(:generating, false)
      |> put_flash(:info, "Generated tip: #{tip.title}")
      |> assign_stats()

    {:noreply, socket}
  end

  @impl true
  def handle_async(:generate_tip, {:ok, {:error, reason}}, socket) do
    socket =
      socket
      |> assign(:generating, false)
      |> put_flash(:error, "Failed to generate tip: #{reason}")

    {:noreply, socket}
  end

  @impl true
  def handle_async(:generate_tip, {:exit, reason}, socket) do
    socket =
      socket
      |> assign(:generating, false)
      |> put_flash(:error, "Tip generation failed: #{inspect(reason)}")

    {:noreply, socket}
  end

  defp assign_stats(socket) do
    assign(socket,
      documents_count: Knowledge.count_documents(),
      chunks_count: Knowledge.count_chunks(),
      embeddings_count: Knowledge.count_chunks_with_embeddings(),
      tips_count: Content.count_tips(),
      draft_tips_count: Content.count_draft_tips(),
      posted_tips_count: Content.count_posted_tips(),
      recent_tips: Content.list_recent_tips(5),
      anthropic_configured: TipGenerator.configured?(),
      voyage_configured: EmbeddingService.configured?(),
      teams_configured: TeamsService.configured?(),
      token_stats: EmbeddingService.token_usage_stats(),
      generating: false
    )
  end
end
