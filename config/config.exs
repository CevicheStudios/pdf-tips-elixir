# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :ai_tips,
  ecto_repos: [AiTips.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configure Oban for background job processing
config :ai_tips, Oban,
  repo: AiTips.Repo,
  plugins: [Oban.Plugins.Pruner],
  queues: [default: 10, embeddings: 5]

# Configure Ueberauth for Azure AD authentication
config :ueberauth, Ueberauth,
  providers: [
    azure_ad: {Ueberauth.Strategy.AzureAD, []}
  ]

# Cloak vault for encrypting API keys (key set in runtime.exs)
config :ai_tips, AiTips.Vault,
  ciphers: [
    default: {Cloak.Ciphers.AES.GCM, tag: "AES.GCM.V1", key: {:system, "CLOAK_KEY"}}
  ]

# Configure the endpoint
config :ai_tips, AiTipsWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: AiTipsWeb.ErrorHTML, json: AiTipsWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: AiTips.PubSub,
  live_view: [signing_salt: "94Cca+1z"]

# Configure the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :ai_tips, AiTips.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.25.4",
  ai_tips: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/* --alias:@=.),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "4.1.12",
  ai_tips: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/css/app.css
    ),
    cd: Path.expand("..", __DIR__)
  ]

# Configure Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
