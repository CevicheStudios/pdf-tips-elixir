defmodule AiTipsWeb.NavComponents do
  @moduledoc """
  Reusable navigation and landing page components.
  """
  use Phoenix.Component
  import AiTipsWeb.CarbonIcons

  @doc """
  Renders a hero section with title, badge, and description.
  """
  attr :title, :string, required: true
  attr :badge, :string, default: nil
  attr :description, :string, required: true
  attr :subtitle, :string, default: nil
  slot :icon

  def hero(assigns) do
    ~H"""
    <div>
      <div :if={@icon != []} class="flex items-center gap-3 mb-4">
        <div class="p-2 bg-primary/10">
          {render_slot(@icon)}
        </div>
      </div>
      <h1 class="flex items-center text-sm font-semibold leading-6 text-base-content">
        {@title}
        <span :if={@badge} class="badge-info ml-3 text-xs">
          {@badge}
        </span>
      </h1>
      <p class="text-[2rem] mt-4 font-semibold leading-10 tracking-tighter text-balance text-base-content">
        {@description}
      </p>
      <p :if={@subtitle} class="mt-4 leading-7 text-base-content/70">
        {@subtitle}
      </p>
    </div>
    """
  end

  @doc """
  Renders a large navigation card with icon and label.
  """
  attr :href, :string, required: true
  attr :icon, :string, required: true
  attr :label, :string, required: true

  def nav_card(assigns) do
    ~H"""
    <a
      href={@href}
      class="group relative px-6 py-4 text-sm font-semibold leading-6 sm:py-6"
    >
      <span class="absolute inset-0 bg-base-200 transition group-hover:bg-base-300 sm:group-hover:scale-105">
      </span>
      <span class="relative flex items-center gap-4 sm:flex-col text-base-content">
        <.carbon_icon name={@icon} class="w-6 h-6" />
        {@label}
      </span>
    </a>
    """
  end

  @doc """
  Renders a grid of navigation cards.
  """
  attr :class, :string, default: nil
  slot :inner_block, required: true

  def nav_card_grid(assigns) do
    ~H"""
    <div class={["grid grid-cols-1 gap-x-6 gap-y-4 sm:grid-cols-3", @class]}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Renders a small link item with icon.
  """
  attr :href, :string, required: true
  attr :icon, :string, required: true
  attr :label, :string, required: true
  attr :external, :boolean, default: false

  def link_item(assigns) do
    ~H"""
    <a
      href={@href}
      class="group -mx-2 -my-0.5 inline-flex items-center gap-3 px-2 py-0.5 hover:bg-base-200 hover:text-base-content"
      target={if @external, do: "_blank"}
    >
      <.carbon_icon name={@icon} class="w-4 h-4 text-base-content/40 group-hover:text-base-content" />
      {@label}
    </a>
    """
  end

  @doc """
  Renders a grid of link items.
  """
  attr :class, :string, default: nil
  slot :inner_block, required: true

  def link_grid(assigns) do
    ~H"""
    <div class={["grid grid-cols-1 gap-y-4 text-sm leading-6 text-base-content/80 sm:grid-cols-2", @class]}>
      {render_slot(@inner_block)}
    </div>
    """
  end
end
