defmodule AiTips.Settings do
  @moduledoc """
  The Settings context for managing app settings.
  """

  import Ecto.Query, warn: false
  alias AiTips.Repo
  alias AiTips.Settings.AppSetting

  @doc """
  Gets the current app settings (singleton pattern).
  Creates a new record if none exists.
  """
  def current do
    case Repo.one(from s in AppSetting, limit: 1) do
      nil ->
        {:ok, setting} = Repo.insert(%AppSetting{})
        setting

      setting ->
        setting
    end
  end

  @doc """
  Updates the app settings.
  """
  def update_settings(attrs) do
    current()
    |> AppSetting.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Adds tokens to the Voyage usage counter.
  """
  def add_voyage_tokens(count) when is_integer(count) and count > 0 do
    setting = current()

    setting
    |> AppSetting.changeset(%{voyage_tokens_used: (setting.voyage_tokens_used || 0) + count})
    |> Repo.update()
  end

  def add_voyage_tokens(_), do: {:ok, current()}

  @doc """
  Resets the Voyage token counter.
  """
  def reset_voyage_tokens do
    current()
    |> AppSetting.changeset(%{voyage_tokens_used: 0})
    |> Repo.update()
  end

  # Convenience delegates to AppSetting

  def anthropic_configured?, do: AppSetting.anthropic_configured?(current())
  def voyage_configured?, do: AppSetting.voyage_configured?(current())
  def teams_configured?, do: AppSetting.teams_configured?(current())
  def power_automate_configured?, do: AppSetting.power_automate_configured?(current())

  def effective_anthropic_key, do: AppSetting.effective_anthropic_key(current())
  def effective_voyage_key, do: AppSetting.effective_voyage_key(current())
  def effective_teams_webhook, do: AppSetting.effective_teams_webhook(current())
  def effective_power_automate_url, do: AppSetting.effective_power_automate_url(current())

  def voyage_near_limit?, do: AppSetting.voyage_near_limit?(current())
  def voyage_over_limit?, do: AppSetting.voyage_over_limit?(current())

  def token_usage_stats do
    setting = current()

    %{
      used: setting.voyage_tokens_used || 0,
      limit: AppSetting.voyage_free_tier_tokens(),
      remaining: AppSetting.voyage_tokens_remaining(setting),
      percentage: AppSetting.voyage_usage_percentage(setting)
    }
  end
end
