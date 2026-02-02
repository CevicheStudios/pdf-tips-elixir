defmodule AiTips.Vault do
  use Cloak.Vault, otp_app: :ai_tips
end

defmodule AiTips.Vault.EncryptedBinary do
  use Cloak.Ecto.Binary, vault: AiTips.Vault
end
