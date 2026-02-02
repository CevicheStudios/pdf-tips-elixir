Postgrex.Types.define(
  PdfTipsElixir.PostgresTypes,
  [Pgvector.Extensions.Vector] ++ Ecto.Adapters.Postgres.extensions(),
  []
)
