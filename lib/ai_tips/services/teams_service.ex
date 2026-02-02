defmodule AiTips.Services.TeamsService do
  @moduledoc """
  Service for posting tips to Microsoft Teams via webhook or Power Automate.

  Supports two modes:
  - **Power Automate**: Posts to Teams AND creates MD file in SharePoint (preferred)
  - **Direct Webhook**: Posts to Teams only (fallback)
  """

  require Logger

  alias AiTips.Settings
  alias AiTips.Content
  alias AiTips.Content.Tip

  @doc """
  Posts a tip to Microsoft Teams (and SharePoint if Power Automate is configured).

  If Power Automate URL is configured, uses it to post to Teams AND create
  a markdown file in SharePoint. Otherwise, falls back to direct webhook.
  """
  def post_tip(%Tip{} = tip) do
    cond do
      Settings.power_automate_configured?() ->
        post_via_power_automate(tip)

      Settings.teams_configured?() ->
        post_via_webhook(tip)

      true ->
        {:error, "No Teams integration configured (neither Power Automate nor webhook)"}
    end
  end

  defp post_via_power_automate(%Tip{} = tip) do
    with {:ok, url} <- get_power_automate_url(),
         payload <- Tip.power_automate_payload(tip),
         {:ok, _} <- send_message(url, payload) do
      Logger.info("Tip posted via Power Automate (Teams + SharePoint)")
      Content.mark_as_posted(tip)
    end
  end

  defp post_via_webhook(%Tip{} = tip) do
    with {:ok, webhook_url} <- get_webhook_url(),
         message <- Tip.teams_message(tip),
         {:ok, _} <- send_message(webhook_url, message) do
      Logger.info("Tip posted via direct Teams webhook (Teams only)")
      Content.mark_as_posted(tip)
    end
  end

  @doc """
  Tests the Teams connection (Power Automate or webhook).
  """
  def test_connection do
    cond do
      Settings.power_automate_configured?() ->
        test_power_automate()

      Settings.teams_configured?() ->
        test_webhook()

      true ->
        {:error, "No Teams integration configured"}
    end
  end

  defp test_power_automate do
    with {:ok, url} <- get_power_automate_url() do
      test_payload = build_test_power_automate_payload()
      send_message(url, test_payload)
    end
  end

  defp test_webhook do
    with {:ok, webhook_url} <- get_webhook_url() do
      test_message = build_test_message()
      send_message(webhook_url, test_message)
    end
  end

  @doc """
  Checks if any Teams integration is configured (Power Automate or webhook).
  """
  def configured? do
    Settings.power_automate_configured?() or Settings.teams_configured?()
  end

  @doc """
  Returns which integration mode is active.
  """
  def integration_mode do
    cond do
      Settings.power_automate_configured?() -> :power_automate
      Settings.teams_configured?() -> :webhook
      true -> :none
    end
  end

  # Private functions

  defp get_power_automate_url do
    case Settings.effective_power_automate_url() do
      nil -> {:error, "Power Automate URL not configured"}
      url -> {:ok, url}
    end
  end

  defp get_webhook_url do
    case Settings.effective_teams_webhook() do
      nil -> {:error, "Teams webhook URL not configured"}
      url -> {:ok, url}
    end
  end

  defp send_message(url, message) do
    case Req.post(url,
           json: message,
           headers: [{"content-type", "application/json"}]
         ) do
      {:ok, %{status: status}} when status in 200..299 ->
        {:ok, :sent}

      {:ok, %{status: 202}} ->
        # Power Automate often returns 202 Accepted
        {:ok, :sent}

      {:ok, %{status: status, body: body}} ->
        Logger.error("Teams post failed: #{status} - #{inspect(body)}")
        {:error, "Teams post failed: #{status}"}

      {:error, reason} ->
        Logger.error("Teams post error: #{inspect(reason)}")
        {:error, "Teams post error: #{inspect(reason)}"}
    end
  end

  defp build_test_power_automate_payload do
    %{
      title: "Connection Test",
      content: "This is a test message from Curated AI Tips.",
      example: "If you see this, the connection is working!",
      source_reference: "Test",
      hashtags: ["#Test", "#ConnectionVerified"],
      markdown: """
      # Connection Test

      This is a test message from Curated AI Tips.

      ## Example

      If you see this, the Power Automate connection is working!

      ## Tags

      #Test #ConnectionVerified

      ---

      **Source:** Test
      **Generated:** #{Calendar.strftime(DateTime.utc_now(), "%B %d, %Y")}
      """,
      filename: "connection-test.md",
      teams_message: build_test_message()
    }
  end

  defp build_test_message do
    %{
      type: "message",
      attachments: [
        %{
          contentType: "application/vnd.microsoft.card.adaptive",
          contentUrl: nil,
          content: %{
            "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
            type: "AdaptiveCard",
            version: "1.4",
            body: [
              %{
                type: "TextBlock",
                text: "Connection Test",
                weight: "bolder",
                size: "medium",
                color: "good"
              },
              %{
                type: "TextBlock",
                text: "Curated AI Tips is connected successfully!",
                wrap: true
              }
            ]
          }
        }
      ]
    }
  end
end
