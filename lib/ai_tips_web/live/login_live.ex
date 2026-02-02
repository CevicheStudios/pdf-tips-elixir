defmodule AiTipsWeb.LoginLive do
  use AiTipsWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-[60vh] flex items-center justify-center">
      <div class="card-enterprise max-w-md w-full">
        <div class="card-enterprise-body p-8">
          <div class="text-center mb-8">
            <div class="flex items-center justify-center gap-2 mb-4">
              <div class="p-2 bg-primary/10">
                <.carbon_icon name="cube" class="w-6 h-6 text-primary" />
              </div>
            </div>
            <h1 class="text-xl font-semibold text-base-content">PDF Tips</h1>
            <p class="text-base-content/60 mt-2">AI-powered productivity tips for Microsoft Teams</p>
          </div>

          <a
            href="/auth/azure_ad"
            class="btn-enterprise-primary w-full justify-center"
          >
            <svg class="w-5 h-5" viewBox="0 0 21 21" fill="currentColor">
              <path d="M0 0h10v10H0V0zm11 0h10v10H11V0zM0 11h10v10H0V11zm11 0h10v10H11V11z"/>
            </svg>
            Sign in with Microsoft
          </a>

          <p class="mt-6 text-center text-sm text-base-content/50">
            Only @xogo.io accounts are allowed.
          </p>
        </div>
      </div>
    </div>
    """
  end
end
