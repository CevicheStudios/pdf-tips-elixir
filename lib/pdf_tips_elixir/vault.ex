defmodule PdfTipsElixir.Vault do
  use Cloak.Vault, otp_app: :pdf_tips_elixir
end

defmodule PdfTipsElixir.Vault.EncryptedBinary do
  use Cloak.Ecto.Binary, vault: PdfTipsElixir.Vault
end
