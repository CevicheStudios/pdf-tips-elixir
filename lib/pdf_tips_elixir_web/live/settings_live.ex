defmodule PdfTipsElixirWeb.SettingsLive do
  use PdfTipsElixirWeb, :live_view

  alias PdfTipsElixir.Settings
  alias PdfTipsElixir.Settings.AppSetting
  alias PdfTipsElixir.Scheduling
  alias PdfTipsElixir.Knowledge
  alias PdfTipsElixir.Services.TeamsService
  alias PdfTipsElixir.Workers.GenerateEmbeddingsWorker

  @impl true
  def mount(_params, _session, socket) do
    app_settings = Settings.current()
    schedule_settings = Scheduling.current_settings()
    logs = Scheduling.list_logs(limit: 20)

    chunks_count = Knowledge.count_chunks()
    embeddings_count = Knowledge.count_chunks_with_embeddings()

    {:ok,
     socket
     |> assign(:page_title, "Settings")
     |> assign(:app_settings, app_settings)
     |> assign(:schedule_settings, schedule_settings)
     |> assign(:logs, logs)
     |> assign(:api_form, build_api_form(app_settings))
     |> assign(:schedule_form, build_schedule_form(schedule_settings))
     |> assign(:testing_teams, false)
     |> assign(:saving, false)
     |> assign(:chunks_count, chunks_count)
     |> assign(:embeddings_count, embeddings_count)
     |> assign(:generating_embeddings, false)}
  end

  defp build_api_form(settings) do
    to_form(%{
      "anthropic_api_key" => "",
      "voyage_api_key" => "",
      "teams_webhook_url" => "",
      "power_automate_url" => "",
      "anthropic_configured" => AppSetting.anthropic_configured?(settings),
      "voyage_configured" => AppSetting.voyage_configured?(settings),
      "teams_configured" => AppSetting.teams_configured?(settings),
      "power_automate_configured" => AppSetting.power_automate_configured?(settings),
      "anthropic_masked" => AppSetting.masked_anthropic_key(settings),
      "voyage_masked" => AppSetting.masked_voyage_key(settings),
      "teams_masked" => AppSetting.masked_teams_webhook(settings),
      "power_automate_masked" => AppSetting.masked_power_automate_url(settings),
      "integration_mode" => TeamsService.integration_mode()
    })
  end

  defp build_schedule_form(settings) do
    to_form(%{
      "enabled" => settings.enabled,
      "schedule" => settings.schedule,
      "topic" => settings.topic || ""
    })
  end

  @impl true
  def handle_event("validate_api", params, socket) do
    {:noreply, assign(socket, :api_form, to_form(params))}
  end

  @impl true
  def handle_event("save_api_keys", params, socket) do
    attrs = %{}
    attrs = if params["anthropic_api_key"] != "", do: Map.put(attrs, :anthropic_api_key, params["anthropic_api_key"]), else: attrs
    attrs = if params["voyage_api_key"] != "", do: Map.put(attrs, :voyage_api_key, params["voyage_api_key"]), else: attrs
    attrs = if params["teams_webhook_url"] != "", do: Map.put(attrs, :teams_webhook_url, params["teams_webhook_url"]), else: attrs
    attrs = if params["power_automate_url"] != "", do: Map.put(attrs, :power_automate_url, params["power_automate_url"]), else: attrs

    if map_size(attrs) > 0 do
      case Settings.update_settings(attrs) do
        {:ok, settings} ->
          {:noreply,
           socket
           |> assign(:app_settings, settings)
           |> assign(:api_form, build_api_form(settings))
           |> put_flash(:info, "API keys saved successfully")}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Failed to save API keys")}
      end
    else
      {:noreply, put_flash(socket, :info, "No changes to save")}
    end
  end

  @impl true
  def handle_event("validate_schedule", params, socket) do
    {:noreply, assign(socket, :schedule_form, to_form(params))}
  end

  @impl true
  def handle_event("save_schedule", params, socket) do
    attrs = %{
      enabled: params["enabled"] == "true",
      schedule: params["schedule"],
      topic: if(params["topic"] == "", do: nil, else: params["topic"])
    }

    case Scheduling.update_settings(attrs) do
      {:ok, settings} ->
        {:noreply,
         socket
         |> assign(:schedule_settings, settings)
         |> assign(:schedule_form, build_schedule_form(settings))
         |> put_flash(:info, "Schedule settings saved")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to save schedule settings")}
    end
  end

  @impl true
  def handle_event("test_teams", _params, socket) do
    socket =
      socket
      |> assign(:testing_teams, true)
      |> start_async(:test_teams, fn -> TeamsService.test_connection() end)

    {:noreply, socket}
  end

  @impl true
  def handle_event("reset_voyage_tokens", _params, socket) do
    case Settings.reset_voyage_tokens() do
      {:ok, settings} ->
        {:noreply,
         socket
         |> assign(:app_settings, settings)
         |> put_flash(:info, "Voyage token counter reset")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to reset token counter")}
    end
  end

  @impl true
  def handle_event("generate_all_embeddings", _params, socket) do
    case GenerateEmbeddingsWorker.enqueue_all() do
      {:ok, _job} ->
        {:noreply,
         socket
         |> assign(:generating_embeddings, true)
         |> put_flash(:info, "Embedding generation started in background. This may take a while...")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to start embedding generation")}
    end
  end

  @impl true
  def handle_event("refresh_embeddings_count", _params, socket) do
    embeddings_count = Knowledge.count_chunks_with_embeddings()

    {:noreply,
     socket
     |> assign(:embeddings_count, embeddings_count)
     |> assign(:generating_embeddings, false)}
  end

  @impl true
  def handle_async(:test_teams, {:ok, {:ok, _}}, socket) do
    {:noreply,
     socket
     |> assign(:testing_teams, false)
     |> put_flash(:info, "Teams connection successful! Check your channel.")}
  end

  @impl true
  def handle_async(:test_teams, {:ok, {:error, reason}}, socket) do
    {:noreply,
     socket
     |> assign(:testing_teams, false)
     |> put_flash(:error, "Teams connection failed: #{reason}")}
  end

  @impl true
  def handle_async(:test_teams, {:exit, reason}, socket) do
    {:noreply,
     socket
     |> assign(:testing_teams, false)
     |> put_flash(:error, "Teams test failed: #{inspect(reason)}")}
  end

  # Template helper functions
  defp log_bg_color("success"), do: "bg-success/10 border border-success/20"
  defp log_bg_color("error"), do: "bg-error/10 border border-error/20"
  defp log_bg_color("skipped"), do: "bg-warning/10 border border-warning/20"
  defp log_bg_color(_), do: "bg-base-200 border border-base-300/50"

  defp log_text_color("success"), do: "text-success"
  defp log_text_color("error"), do: "text-error"
  defp log_text_color("skipped"), do: "text-warning"
  defp log_text_color(_), do: "text-base-content/70"

  defp format_datetime(nil), do: "Never"
  defp format_datetime(datetime), do: Calendar.strftime(datetime, "%b %d, %Y at %I:%M %p")
end
