defmodule PdfTipsElixir.Repo do
  use Ecto.Repo,
    otp_app: :pdf_tips_elixir,
    adapter: Ecto.Adapters.Postgres
end
