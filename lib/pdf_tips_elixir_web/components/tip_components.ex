defmodule PdfTipsElixirWeb.TipComponents do
  @moduledoc """
  Reusable UI components for the tips feature.
  """
  use Phoenix.Component
  use Phoenix.VerifiedRoutes,
    endpoint: PdfTipsElixirWeb.Endpoint,
    router: PdfTipsElixirWeb.Router

  import PdfTipsElixirWeb.CarbonIcons

  # Page structure components

  @doc """
  Renders a page header with title and optional description.
  """
  attr :title, :string, required: true
  attr :description, :string, default: nil

  def page_header(assigns) do
    ~H"""
    <div>
      <h1 class="text-2xl font-semibold text-base-content">{@title}</h1>
      <p :if={@description} class="text-base-content/60 mt-1">{@description}</p>
    </div>
    """
  end

  @doc """
  Renders an enterprise-style card with optional header.
  """
  attr :class, :string, default: nil
  slot :header
  slot :inner_block, required: true

  def card(assigns) do
    ~H"""
    <div class={["card-enterprise", @class]}>
      <div :if={@header != []} class="card-enterprise-header">
        {render_slot(@header)}
      </div>
      <div class="card-enterprise-body">
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  @doc """
  Renders a card header with icon and title.
  """
  attr :icon, :string, required: true
  attr :title, :string, required: true
  attr :description, :string, default: nil
  slot :actions

  def card_header(assigns) do
    ~H"""
    <div class="flex items-center justify-between">
      <div class="flex items-center gap-3">
        <div class="p-2 bg-primary/10">
          <.carbon_icon name={@icon} class="w-5 h-5 text-primary" />
        </div>
        <div>
          <h2 class="font-medium text-base-content">{@title}</h2>
          <p :if={@description} class="text-sm text-base-content/50">{@description}</p>
        </div>
      </div>
      {render_slot(@actions)}
    </div>
    """
  end

  @doc """
  Renders an empty state placeholder.
  """
  attr :icon, :string, default: "idea"
  attr :message, :string, required: true
  attr :description, :string, default: nil

  def empty_state(assigns) do
    ~H"""
    <div class="card-enterprise">
      <div class="card-enterprise-body text-center py-12">
        <.carbon_icon name={@icon} class="w-12 h-12 mx-auto text-base-content/20" />
        <p class="mt-4 text-base-content/60">{@message}</p>
        <p :if={@description} class="text-sm text-base-content/40 mt-1">{@description}</p>
      </div>
    </div>
    """
  end

  # Status components

  @doc """
  Renders a status badge.
  """
  attr :variant, :atom, values: [:success, :warning, :info], required: true
  slot :inner_block, required: true

  def badge(assigns) do
    ~H"""
    <span class={badge_class(@variant)}>
      {render_slot(@inner_block)}
    </span>
    """
  end

  defp badge_class(:success), do: "badge-success"
  defp badge_class(:warning), do: "badge-warning"
  defp badge_class(:info), do: "badge-info"

  @doc """
  Renders a loading spinner.
  """
  attr :class, :string, default: "w-4 h-4"

  def spinner(assigns) do
    ~H"""
    <svg class={[@class, "loading-spinner"]} xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
      <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
      <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
    </svg>
    """
  end

  # Topic selection components

  @doc """
  Renders a selectable topic pill button.
  """
  attr :topic, :string, required: true
  attr :selected, :boolean, default: false
  attr :disabled, :boolean, default: false

  def topic_pill(assigns) do
    ~H"""
    <button
      phx-click="select_topic"
      phx-value-topic={@topic}
      disabled={@disabled}
      class={["topic-pill", @selected && "selected"]}
    >
      {@topic}
    </button>
    """
  end

  @doc """
  Renders a topic group card with pills.
  """
  attr :group, :map, required: true
  attr :selected_topic, :string, default: nil
  attr :disabled, :boolean, default: false

  def topic_group(assigns) do
    ~H"""
    <div class="p-4 bg-base-200/30 border border-base-300/30">
      <div class="flex items-center gap-2 mb-3">
        <.carbon_icon name={@group.icon} class="w-4 h-4 text-base-content/50" />
        <h3 class="text-sm font-medium text-base-content/70">{@group.name}</h3>
      </div>
      <div class="flex flex-wrap gap-1.5">
        <.topic_pill
          :for={topic <- @group.topics}
          topic={topic}
          selected={@selected_topic == topic}
          disabled={@disabled}
        />
      </div>
    </div>
    """
  end

  @doc """
  Renders the selected topic display with clear button.
  """
  attr :topic, :string, required: true

  def selected_topic_display(assigns) do
    ~H"""
    <div class="flex items-center justify-between p-3 bg-primary/5 border border-primary/20">
      <div class="flex items-center gap-3">
        <div class="p-1.5 bg-primary/10">
          <.carbon_icon name="tag" class="w-4 h-4 text-primary" />
        </div>
        <div>
          <p class="text-xs text-primary/70 font-medium uppercase tracking-wider">Selected Topic</p>
          <p class="text-sm font-medium text-base-content">{@topic}</p>
        </div>
      </div>
      <button
        phx-click="clear_topic"
        class="p-1.5 text-base-content/50 hover:text-base-content hover:bg-base-300/50 transition-colors"
      >
        <.carbon_icon name="close" class="w-4 h-4" />
      </button>
    </div>
    """
  end

  # Button components

  @doc """
  Renders a primary action button with optional loading state.
  """
  attr :loading, :boolean, default: false
  attr :disabled, :boolean, default: false
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(phx-click)
  slot :inner_block, required: true
  slot :loading_text

  def action_button(assigns) do
    ~H"""
    <button
      disabled={@loading || @disabled}
      class={["btn-enterprise-primary", @class]}
      {@rest}
    >
      <%= if @loading do %>
        <.spinner class="w-4 h-4" />
        {render_slot(@loading_text)}
      <% else %>
        {render_slot(@inner_block)}
      <% end %>
    </button>
    """
  end

  # Tip list components

  @doc """
  Renders a single tip card in the list.
  """
  attr :tip, :map, required: true
  attr :posting, :integer, default: nil

  def tip_card(assigns) do
    ~H"""
    <div class="card-enterprise group">
      <div class="p-5">
        <div class="flex items-start justify-between gap-4">
          <.link navigate={~p"/tips/#{@tip.id}"} class="flex-1 min-w-0">
            <h3 class="font-medium text-base-content group-hover:text-primary transition-colors">
              {@tip.title}
            </h3>
            <p class="text-sm text-base-content/60 mt-1.5 line-clamp-2">
              {String.slice(@tip.content, 0..150)}<%= if String.length(@tip.content) > 150, do: "..." %>
            </p>
            <div class="flex items-center gap-4 mt-3 text-xs text-base-content/50">
              <span :if={@tip.source_reference} class="flex items-center gap-1">
                <.carbon_icon name="document" class="w-3.5 h-3.5" />
                {@tip.source_reference}
              </span>
              <span class="flex items-center gap-1">
                <.carbon_icon name="time" class="w-3.5 h-3.5" />
                <%= if @tip.posted do %>
                  Posted {format_datetime(@tip.posted_at)}
                <% else %>
                  Created {format_datetime(@tip.inserted_at)}
                <% end %>
              </span>
            </div>
          </.link>

          <.tip_actions tip={@tip} posting={@posting} />
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders the action buttons for a tip card.
  """
  attr :tip, :map, required: true
  attr :posting, :integer, default: nil

  def tip_actions(assigns) do
    ~H"""
    <div class="flex items-center gap-2 flex-shrink-0">
      <%= if not @tip.posted do %>
        <button
          phx-click="post_to_teams"
          phx-value-id={@tip.id}
          disabled={@posting == @tip.id}
          class="btn-enterprise-success text-xs py-2"
        >
          <%= if @posting == @tip.id do %>
            <.spinner class="w-3.5 h-3.5" />
            Posting...
          <% else %>
            <.carbon_icon name="send" class="w-3.5 h-3.5" />
            Post to Teams
          <% end %>
        </button>
      <% else %>
        <.badge variant={:success}>Posted</.badge>
      <% end %>
      <button
        phx-click="delete"
        phx-value-id={@tip.id}
        data-confirm="Are you sure you want to delete this tip?"
        class="p-2 text-base-content/40 hover:text-error hover:bg-error/10 transition-colors"
      >
        <.carbon_icon name="trash-can" class="w-4 h-4" />
      </button>
    </div>
    """
  end

  # Tab components

  @doc """
  Renders tab navigation.
  """
  attr :current_tab, :string, required: true
  slot :inner_block, required: true

  def tabs(assigns) do
    ~H"""
    <div class="tabs-enterprise">
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Renders a single tab link.
  """
  attr :tab, :string, required: true
  attr :current, :string, required: true
  attr :patch, :string, required: true
  slot :inner_block, required: true

  def tab(assigns) do
    ~H"""
    <.link
      patch={@patch}
      class={["tab-enterprise", @tab == @current && "active"]}
    >
      {render_slot(@inner_block)}
    </.link>
    """
  end

  # Navigation components

  @doc """
  Renders a back link for detail pages.
  """
  attr :to, :string, required: true
  attr :label, :string, required: true

  def back_link(assigns) do
    ~H"""
    <div class="flex items-center gap-4">
      <.link navigate={@to} class="text-primary hover:text-primary/80 transition-colors flex items-center gap-1">
        <.carbon_icon name="arrow-left" class="w-4 h-4" />
        {@label}
      </.link>
    </div>
    """
  end

  # Stats & metrics components

  @doc """
  Renders a stat card for dashboard metrics.
  """
  attr :value, :any, required: true
  attr :label, :string, required: true
  attr :subtitle, :string, default: nil
  attr :icon, :string, required: true
  attr :icon_color, :string, default: "primary"

  def stat_card(assigns) do
    ~H"""
    <div class="stat-card">
      <div class="flex items-start justify-between">
        <div>
          <p class="stat-card-value">{@value}</p>
          <p class="stat-card-label">{@label}</p>
          <p :if={@subtitle} class="stat-card-subtitle">{@subtitle}</p>
        </div>
        <div class={"p-2 bg-#{@icon_color}/10"}>
          <.carbon_icon name={@icon} class={"w-5 h-5 text-#{@icon_color}"} />
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders a progress bar.
  """
  attr :percentage, :integer, required: true
  attr :danger_threshold, :integer, default: 80
  attr :class, :string, default: nil

  def progress_bar(assigns) do
    ~H"""
    <div class={["progress-enterprise", @class]}>
      <div
        class={["progress-enterprise-fill", @percentage >= @danger_threshold && "!bg-error"]}
        style={"width: #{min(@percentage, 100)}%"}
      />
    </div>
    """
  end

  @doc """
  Renders a config status row for system status display.
  """
  attr :name, :string, required: true
  attr :description, :string, required: true
  attr :configured, :boolean, required: true

  def config_status_row(assigns) do
    ~H"""
    <div class="flex items-center justify-between">
      <div class="flex items-center gap-3">
        <div class={["w-2 h-2 rounded-full", @configured && "bg-success" || "bg-error"]}></div>
        <div>
          <p class="text-sm font-medium text-base-content">{@name}</p>
          <p class="text-xs text-base-content/50">{@description}</p>
        </div>
      </div>
      <span class={@configured && "badge-success" || "badge-error"}>
        {if @configured, do: "Active", else: "Not configured"}
      </span>
    </div>
    """
  end

  @doc """
  Renders a processing indicator banner.
  """
  attr :message, :string, default: "Processing... This may take a moment."

  def processing_indicator(assigns) do
    ~H"""
    <div class="flex items-center gap-3 p-4 bg-info/10 border border-info/20">
      <.spinner class="w-5 h-5 text-info" />
      <span class="text-sm text-info">{@message}</span>
    </div>
    """
  end

  # Document components

  @doc """
  Renders a document list item.
  """
  attr :doc, :map, required: true

  def document_item(assigns) do
    ~H"""
    <div class="flex items-center justify-between p-4 hover:bg-base-200/30 transition-colors group">
      <.link navigate={~p"/documents/#{@doc.id}"} class="flex-1 flex items-center gap-4">
        <div class={["p-2", @doc.source_type == "pdf" && "bg-error/10" || "bg-info/10"]}>
          <.carbon_icon
            name={if @doc.source_type == "pdf", do: "pdf", else: "link"}
            class={"w-5 h-5 #{if @doc.source_type == "pdf", do: "text-error", else: "text-info"}"}
          />
        </div>
        <div class="flex-1 min-w-0">
          <h3 class="font-medium text-base-content group-hover:text-primary transition-colors truncate">
            {@doc.name}
          </h3>
          <div class="flex items-center gap-3 mt-1">
            <span class={["text-xs font-medium uppercase", @doc.source_type == "pdf" && "text-error" || "text-info"]}>
              {@doc.source_type}
            </span>
            <span class="text-xs text-base-content/50">
              <%= if @doc.processed do %>
                {if @doc.page_count, do: "#{@doc.page_count} pages", else: "Processed"}
              <% else %>
                <span class="text-warning">Processing...</span>
              <% end %>
            </span>
          </div>
        </div>
      </.link>
      <button
        phx-click="delete"
        phx-value-id={@doc.id}
        data-confirm="Are you sure you want to delete this document and all its chunks?"
        class="p-2 text-base-content/40 hover:text-error hover:bg-error/10 transition-colors ml-2"
      >
        <.carbon_icon name="trash-can" class="w-4 h-4" />
      </button>
    </div>
    """
  end

  @doc """
  Renders a chunk list item.
  """
  attr :chunk, :map, required: true

  def chunk_item(assigns) do
    ~H"""
    <div class="p-4 hover:bg-base-200/30 transition-colors">
      <div class="flex items-start justify-between">
        <div class="flex-1">
          <div class="flex items-center gap-2 flex-wrap mb-2">
            <span class="text-sm font-medium text-base-content/70">
              Chunk #{@chunk.chunk_index + 1}
            </span>
            <span :if={@chunk.page_number} class="badge-neutral">
              Page {@chunk.page_number}
            </span>
            <span class={@chunk.chunk_vector && "badge-success" || "badge-warning"}>
              {if @chunk.chunk_vector, do: "Has embedding", else: "No embedding"}
            </span>
            <span :if={@chunk.times_used > 0} class="badge-info">
              Used {@chunk.times_used}x
            </span>
          </div>
          <p class="text-sm text-base-content/80 whitespace-pre-wrap">
            {String.slice(@chunk.content, 0..500)}<%= if String.length(@chunk.content) > 500, do: "..." %>
          </p>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders a recent tip item for the dashboard.
  """
  attr :tip, :map, required: true

  def recent_tip_item(assigns) do
    ~H"""
    <.link navigate={~p"/tips/#{@tip.id}"} class="block p-4 bg-base-200/50 hover:bg-base-200 transition-colors group">
      <div class="flex items-start justify-between gap-4">
        <div class="flex-1 min-w-0">
          <h3 class="font-medium text-base-content group-hover:text-primary transition-colors truncate">
            {@tip.title}
          </h3>
          <p class="text-sm text-base-content/60 mt-1 line-clamp-2">
            {String.slice(@tip.content, 0..100)}...
          </p>
        </div>
        <span class={@tip.posted && "badge-success" || "badge-warning"}>
          {if @tip.posted, do: "Posted", else: "Draft"}
        </span>
      </div>
    </.link>
    """
  end

  # Helper functions

  defp format_datetime(nil), do: "Unknown"
  defp format_datetime(datetime) do
    Calendar.strftime(datetime, "%b %d, %Y at %I:%M %p")
  end

  @doc """
  Formats a number with K/M suffixes.
  """
  def format_number(num) when num >= 1_000_000, do: "#{Float.round(num / 1_000_000, 1)}M"
  def format_number(num) when num >= 1_000, do: "#{Float.round(num / 1_000, 1)}K"
  def format_number(num), do: "#{num}"

  @doc """
  Formats a relative time (e.g., "5m ago").
  """
  def format_relative_time(datetime) do
    diff = DateTime.diff(DateTime.utc_now(), datetime, :second)

    cond do
      diff < 60 -> "just now"
      diff < 3600 -> "#{div(diff, 60)}m ago"
      diff < 86400 -> "#{div(diff, 3600)}h ago"
      diff < 604_800 -> "#{div(diff, 86400)}d ago"
      true -> Calendar.strftime(datetime, "%b %d")
    end
  end
end
