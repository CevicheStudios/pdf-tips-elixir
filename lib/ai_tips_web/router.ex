defmodule AiTipsWeb.Router do
  use AiTipsWeb, :router

  import AiTipsWeb.Plugs.Auth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {AiTipsWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Public routes (no auth required)
  scope "/", AiTipsWeb do
    pipe_through :browser

    live "/login", LoginLive, :index
    get "/logout", AuthController, :logout
  end

  # OAuth routes
  scope "/auth", AiTipsWeb do
    pipe_through :browser

    get "/:provider", AuthController, :request
    get "/:provider/callback", AuthController, :callback
  end

  # Protected routes (require authentication)
  scope "/", AiTipsWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :authenticated,
      on_mount: [{AiTipsWeb.UserAuth, :ensure_authenticated}] do
      live "/", DashboardLive, :index
      live "/documents", DocumentLive.Index, :index
      live "/documents/:id", DocumentLive.Show, :show
      live "/tips", TipLive.Index, :index
      live "/tips/:id", TipLive.Show, :show
      live "/settings", SettingsLive, :index
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", AiTipsWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:ai_tips, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: AiTipsWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
