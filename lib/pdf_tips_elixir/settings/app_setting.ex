defmodule PdfTipsElixir.Settings.AppSetting do
  use Ecto.Schema
  import Ecto.Changeset

  alias PdfTipsElixir.Vault

  # Voyage AI free tier: 200M tokens
  @voyage_free_tier_tokens 200_000_000
  @voyage_warning_threshold 0.8

  schema "app_settings" do
    field :anthropic_api_key, Vault.EncryptedBinary
    field :voyage_api_key, Vault.EncryptedBinary
    field :teams_webhook_url, Vault.EncryptedBinary
    field :power_automate_url, Vault.EncryptedBinary
    field :voyage_tokens_used, :integer, default: 0

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(app_setting, attrs) do
    app_setting
    |> cast(attrs, [:anthropic_api_key, :voyage_api_key, :teams_webhook_url, :power_automate_url, :voyage_tokens_used])
  end

  # API key helpers - database value takes precedence over env vars

  def effective_anthropic_key(%__MODULE__{anthropic_api_key: key}) when is_binary(key) and key != "" do
    key
  end

  def effective_anthropic_key(_), do: System.get_env("ANTHROPIC_API_KEY")

  def effective_voyage_key(%__MODULE__{voyage_api_key: key}) when is_binary(key) and key != "" do
    key
  end

  def effective_voyage_key(_), do: System.get_env("VOYAGE_API_KEY")

  def effective_teams_webhook(%__MODULE__{teams_webhook_url: url}) when is_binary(url) and url != "" do
    url
  end

  def effective_teams_webhook(_), do: System.get_env("TEAMS_WEBHOOK_URL")

  def effective_power_automate_url(%__MODULE__{power_automate_url: url}) when is_binary(url) and url != "" do
    url
  end

  def effective_power_automate_url(_), do: System.get_env("POWER_AUTOMATE_URL")

  # Configuration status checks

  def anthropic_configured?(setting), do: effective_anthropic_key(setting) != nil
  def voyage_configured?(setting), do: effective_voyage_key(setting) != nil
  def teams_configured?(setting), do: effective_teams_webhook(setting) != nil
  def power_automate_configured?(setting), do: effective_power_automate_url(setting) != nil

  # Source checks (database vs env)

  def anthropic_from_db?(%__MODULE__{anthropic_api_key: key}) when is_binary(key) and key != "", do: true
  def anthropic_from_db?(_), do: false

  def voyage_from_db?(%__MODULE__{voyage_api_key: key}) when is_binary(key) and key != "", do: true
  def voyage_from_db?(_), do: false

  def teams_from_db?(%__MODULE__{teams_webhook_url: url}) when is_binary(url) and url != "", do: true
  def teams_from_db?(_), do: false

  def power_automate_from_db?(%__MODULE__{power_automate_url: url}) when is_binary(url) and url != "", do: true
  def power_automate_from_db?(_), do: false

  # Masked display helpers

  def masked_anthropic_key(setting) do
    setting |> effective_anthropic_key() |> mask_key()
  end

  def masked_voyage_key(setting) do
    setting |> effective_voyage_key() |> mask_key()
  end

  def masked_teams_webhook(setting) do
    setting |> effective_teams_webhook() |> mask_url()
  end

  def masked_power_automate_url(setting) do
    setting |> effective_power_automate_url() |> mask_url()
  end

  defp mask_key(nil), do: nil
  defp mask_key(key) when byte_size(key) <= 8, do: key

  defp mask_key(key) do
    prefix = String.slice(key, 0, 7)
    suffix = String.slice(key, -4, 4)
    "#{prefix}...#{suffix}"
  end

  defp mask_url(nil), do: nil
  defp mask_url(url) when byte_size(url) <= 20, do: url

  defp mask_url(url) do
    case URI.parse(url) do
      %URI{host: host} when is_binary(host) ->
        suffix = String.slice(url, -8, 8)
        "#{host}/...#{suffix}"

      _ ->
        String.slice(url, 0, 20) <> "..."
    end
  end

  # Voyage token tracking

  def voyage_free_tier_tokens, do: @voyage_free_tier_tokens

  def voyage_tokens_remaining(%__MODULE__{voyage_tokens_used: used}) do
    @voyage_free_tier_tokens - (used || 0)
  end

  def voyage_usage_percentage(%__MODULE__{voyage_tokens_used: used}) do
    Float.round((used || 0) / @voyage_free_tier_tokens * 100, 2)
  end

  def voyage_near_limit?(%__MODULE__{} = setting) do
    voyage_usage_percentage(setting) >= @voyage_warning_threshold * 100
  end

  def voyage_over_limit?(%__MODULE__{voyage_tokens_used: used}) do
    (used || 0) >= @voyage_free_tier_tokens
  end
end
