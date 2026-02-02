defmodule PdfTipsElixirWeb.TipLive.Index do
  use PdfTipsElixirWeb, :live_view

  alias PdfTipsElixir.Content
  alias PdfTipsElixir.Services.{TipGenerator, TeamsService, EmbeddingService}

  @topic_groups [
    %{
      name: "Prompt Techniques",
      icon: "idea",
      topics: [
        "chain of thought prompting",
        "few-shot examples",
        "zero-shot prompting",
        "prompt chaining",
        "role prompting"
      ]
    },
    %{
      name: "Structure & Format",
      icon: "document",
      topics: [
        "XML tags in prompts",
        "JSON output formatting",
        "structured outputs",
        "markdown formatting",
        "prefilling responses"
      ]
    },
    %{
      name: "Advanced Patterns",
      icon: "lightning",
      topics: [
        "system prompts",
        "extended thinking",
        "long context handling",
        "multi-turn conversations",
        "tool use and function calling"
      ]
    },
    %{
      name: "Use Cases",
      icon: "folder",
      topics: [
        "code generation",
        "code review",
        "documentation writing",
        "data analysis",
        "content summarization"
      ]
    },
    %{
      name: "Best Practices",
      icon: "checkmark-filled",
      topics: [
        "prompt optimization",
        "reducing hallucinations",
        "improving accuracy",
        "cost optimization",
        "error handling"
      ]
    }
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Tips")
     |> assign(:tab, "drafts")
     |> assign(:tips, Content.list_draft_tips())
     |> assign(:generating, false)
     |> assign(:posting, nil)
     |> assign(:selected_topic, nil)
     |> assign(:topic_groups, @topic_groups)
     |> assign(:embeddings_configured, EmbeddingService.configured?())}
  end

  @impl true
  def handle_params(%{"tab" => tab}, _uri, socket) when tab in ["drafts", "posted"] do
    tips =
      case tab do
        "drafts" -> Content.list_draft_tips()
        "posted" -> Content.list_posted_tips()
      end

    {:noreply, assign(socket, tab: tab, tips: tips)}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("select_topic", %{"topic" => topic}, socket) do
    {:noreply, assign(socket, :selected_topic, topic)}
  end

  @impl true
  def handle_event("clear_topic", _params, socket) do
    {:noreply, assign(socket, :selected_topic, nil)}
  end

  @impl true
  def handle_event("generate_random", _params, socket) do
    socket =
      socket
      |> assign(:generating, true)
      |> assign(:selected_topic, nil)
      |> start_async(:generate_tip, fn -> TipGenerator.generate_tip() end)

    {:noreply, socket}
  end

  @impl true
  def handle_event("generate_tip", _params, socket) do
    topic = socket.assigns.selected_topic
    opts = if topic, do: [topic: topic], else: []

    socket =
      socket
      |> assign(:generating, true)
      |> start_async(:generate_tip, fn -> TipGenerator.generate_tip(opts) end)

    {:noreply, socket}
  end

  @impl true
  def handle_event("post_to_teams", %{"id" => id}, socket) do
    tip = Content.get_tip(id)

    socket =
      socket
      |> assign(:posting, String.to_integer(id))
      |> start_async(:post_to_teams, fn -> TeamsService.post_tip(tip) end)

    {:noreply, socket}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    tip = Content.get_tip(id)

    case Content.delete_tip(tip) do
      {:ok, _} ->
        tips =
          case socket.assigns.tab do
            "drafts" -> Content.list_draft_tips()
            "posted" -> Content.list_posted_tips()
          end

        {:noreply,
         socket
         |> put_flash(:info, "Tip deleted")
         |> assign(:tips, tips)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to delete tip")}
    end
  end

  @impl true
  def handle_async(:generate_tip, {:ok, {:ok, tip}}, socket) do
    {:noreply,
     socket
     |> assign(:generating, false)
     |> assign(:tips, Content.list_draft_tips())
     |> assign(:tab, "drafts")
     |> assign(:selected_topic, nil)
     |> put_flash(:info, "Generated tip: #{tip.title}")}
  end

  @impl true
  def handle_async(:generate_tip, {:ok, {:error, reason}}, socket) do
    {:noreply,
     socket
     |> assign(:generating, false)
     |> put_flash(:error, "Failed to generate tip: #{reason}")}
  end

  @impl true
  def handle_async(:generate_tip, {:exit, reason}, socket) do
    {:noreply,
     socket
     |> assign(:generating, false)
     |> put_flash(:error, "Tip generation failed: #{inspect(reason)}")}
  end

  @impl true
  def handle_async(:post_to_teams, {:ok, {:ok, _tip}}, socket) do
    tips =
      case socket.assigns.tab do
        "drafts" -> Content.list_draft_tips()
        "posted" -> Content.list_posted_tips()
      end

    {:noreply,
     socket
     |> assign(:posting, nil)
     |> assign(:tips, tips)
     |> put_flash(:info, "Tip posted to Teams successfully")}
  end

  @impl true
  def handle_async(:post_to_teams, {:ok, {:error, reason}}, socket) do
    {:noreply,
     socket
     |> assign(:posting, nil)
     |> put_flash(:error, "Failed to post to Teams: #{reason}")}
  end

  @impl true
  def handle_async(:post_to_teams, {:exit, reason}, socket) do
    {:noreply,
     socket
     |> assign(:posting, nil)
     |> put_flash(:error, "Teams posting failed: #{inspect(reason)}")}
  end
end
