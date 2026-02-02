defmodule AiTips.Repo do
  use Ecto.Repo,
    otp_app: :ai_tips,
    adapter: Ecto.Adapters.Postgres
end
