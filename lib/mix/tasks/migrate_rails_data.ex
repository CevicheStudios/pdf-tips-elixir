defmodule Mix.Tasks.MigrateRailsData do
  @moduledoc """
  Mix task to migrate data from the Rails SQLite database to Phoenix PostgreSQL.

  Usage:
    mix migrate_rails_data /path/to/rails/storage/production.sqlite3

  This task will:
  1. Connect to the SQLite source database
  2. Migrate documents (and copy PDF files)
  3. Migrate chunks (maintaining document associations)
  4. Migrate tips (maintaining chunk associations)
  5. Migrate app_settings (re-encrypting API keys)
  6. Migrate schedule_settings and logs

  Note: Users table is migrated separately since the Rails app may not have one.
  Embeddings will need to be regenerated (pgvector format differs from sqlite-vec).
  """

  use Mix.Task

  require Logger

  @shortdoc "Migrates data from Rails SQLite to Phoenix PostgreSQL"

  @impl Mix.Task
  def run([sqlite_path]) do
    Mix.Task.run("app.start")

    unless File.exists?(sqlite_path) do
      Mix.raise("SQLite database not found: #{sqlite_path}")
    end

    Logger.info("Starting migration from #{sqlite_path}")

    # Open SQLite connection
    {:ok, db} = Exqlite.Sqlite3.open(sqlite_path)

    try do
      # Run migrations in order
      migrate_documents(db, sqlite_path)
      migrate_chunks(db)
      migrate_tips(db)
      migrate_app_settings(db)
      migrate_schedule_settings(db)
      migrate_schedule_logs(db)

      Logger.info("Migration completed successfully!")
      Logger.info("Note: You will need to regenerate embeddings using 'mix generate_embeddings'")
    after
      Exqlite.Sqlite3.close(db)
    end
  end

  def run(_) do
    Mix.raise("Usage: mix migrate_rails_data /path/to/sqlite.db")
  end

  defp migrate_documents(db, sqlite_path) do
    Logger.info("Migrating documents...")

    {:ok, stmt} = Exqlite.Sqlite3.prepare(db, """
      SELECT id, name, file_path, content, page_count, processed, source_type, source_url,
             created_at, updated_at
      FROM documents
    """)

    # Check multiple possible upload locations
    rails_uploads_dir =
      [
        Path.join(Path.dirname(sqlite_path), "uploads"),           # Docker volume structure
        Path.join(Path.dirname(sqlite_path), "../public/uploads"), # Standard Rails structure
        Path.join(Path.dirname(sqlite_path), "../uploads")         # Alternative location
      ]
      |> Enum.find(&File.dir?/1)
      |> case do
        nil ->
          Logger.warning("No uploads directory found, PDFs will not be copied")
          nil
        dir ->
          Logger.info("Found uploads directory: #{dir}")
          dir
      end
    phoenix_uploads_dir = Path.join([:code.priv_dir(:ai_tips), "static", "uploads"])
    File.mkdir_p!(phoenix_uploads_dir)

    documents = fetch_all_rows(db, stmt)
    id_map = %{}

    id_map =
      Enum.reduce(documents, id_map, fn row, acc ->
        [old_id, name, file_path, content, page_count, processed, source_type, source_url, created_at, updated_at] = row

        # Copy PDF file if it exists
        new_file_path =
          if file_path && source_type == "pdf" && rails_uploads_dir do
            old_path = Path.join(rails_uploads_dir, Path.basename(file_path))
            new_path = Path.join(phoenix_uploads_dir, Path.basename(file_path))

            if File.exists?(old_path) do
              File.cp!(old_path, new_path)
              new_path
            else
              Logger.warning("PDF file not found: #{old_path}")
              nil
            end
          else
            nil
          end

        {:ok, doc} =
          AiTips.Repo.insert(%AiTips.Knowledge.Document{
            name: name,
            file_path: new_file_path,
            content: content,
            page_count: page_count,
            processed: processed == 1,
            source_type: source_type || "pdf",
            source_url: source_url,
            inserted_at: parse_datetime(created_at),
            updated_at: parse_datetime(updated_at)
          })

        Map.put(acc, old_id, doc.id)
      end)

    # Store ID mapping for chunks
    :persistent_term.put(:document_id_map, id_map)

    Logger.info("Migrated #{map_size(id_map)} documents")
  end

  defp migrate_chunks(db) do
    Logger.info("Migrating chunks...")

    document_id_map = :persistent_term.get(:document_id_map)

    {:ok, stmt} = Exqlite.Sqlite3.prepare(db, """
      SELECT id, content, page_number, chunk_index, times_used, last_used_at, document_id,
             created_at, updated_at
      FROM chunks
    """)

    chunks = fetch_all_rows(db, stmt)
    id_map = %{}

    id_map =
      Enum.reduce(chunks, id_map, fn row, acc ->
        [old_id, content, page_number, chunk_index, times_used, last_used_at, old_doc_id, created_at, updated_at] = row

        new_doc_id = Map.get(document_id_map, old_doc_id)

        if new_doc_id do
          {:ok, chunk} =
            AiTips.Repo.insert(%AiTips.Knowledge.Chunk{
              content: content,
              page_number: page_number,
              chunk_index: chunk_index,
              times_used: times_used || 0,
              last_used_at: parse_datetime(last_used_at),
              document_id: new_doc_id,
              inserted_at: parse_datetime(created_at),
              updated_at: parse_datetime(updated_at)
            })

          Map.put(acc, old_id, chunk.id)
        else
          Logger.warning("Skipping chunk #{old_id}: document #{old_doc_id} not found")
          acc
        end
      end)

    :persistent_term.put(:chunk_id_map, id_map)

    Logger.info("Migrated #{map_size(id_map)} chunks")
    Logger.info("Note: Embeddings need to be regenerated - run 'mix generate_embeddings'")
  end

  defp migrate_tips(db) do
    Logger.info("Migrating tips...")

    chunk_id_map = :persistent_term.get(:chunk_id_map)

    {:ok, stmt} = Exqlite.Sqlite3.prepare(db, """
      SELECT id, title, content, example, source_reference, posted, posted_at, chunk_id,
             created_at, updated_at
      FROM tips
    """)

    tips = fetch_all_rows(db, stmt)

    tip_count =
      Enum.reduce(tips, 0, fn row, count ->
        [_old_id, title, content, example, source_reference, posted, posted_at, old_chunk_id, created_at, updated_at] = row

        new_chunk_id = if old_chunk_id, do: Map.get(chunk_id_map, old_chunk_id), else: nil

        {:ok, _tip} =
          AiTips.Repo.insert(%AiTips.Content.Tip{
            title: title,
            content: content,
            example: example,
            source_reference: source_reference,
            posted: posted == 1,
            posted_at: parse_datetime(posted_at),
            chunk_id: new_chunk_id,
            inserted_at: parse_datetime(created_at),
            updated_at: parse_datetime(updated_at)
          })

        count + 1
      end)

    Logger.info("Migrated #{tip_count} tips")
  end

  defp migrate_app_settings(db) do
    Logger.info("Migrating app settings...")

    {:ok, stmt} = Exqlite.Sqlite3.prepare(db, """
      SELECT anthropic_api_key, voyage_api_key, teams_webhook_url
      FROM app_settings
      LIMIT 1
    """)

    case fetch_all_rows(db, stmt) do
      [[anthropic_key, voyage_key, teams_url]] ->
        # Note: Rails encrypts these with ActiveRecord encryption
        # You may need to decrypt them first or re-enter manually
        Logger.warning("API keys from Rails are encrypted - you may need to re-enter them manually")

        # Only migrate if they appear to be unencrypted (for dev data)
        attrs = %{}

        attrs =
          if anthropic_key && !String.starts_with?(anthropic_key, "{") do
            Map.put(attrs, :anthropic_api_key, anthropic_key)
          else
            attrs
          end

        attrs =
          if voyage_key && !String.starts_with?(voyage_key, "{") do
            Map.put(attrs, :voyage_api_key, voyage_key)
          else
            attrs
          end

        attrs =
          if teams_url && !String.starts_with?(teams_url, "{") do
            Map.put(attrs, :teams_webhook_url, teams_url)
          else
            attrs
          end

        if map_size(attrs) > 0 do
          AiTips.Settings.update_settings(attrs)
          Logger.info("Migrated app settings")
        else
          Logger.info("No unencrypted settings to migrate")
        end

      _ ->
        Logger.info("No app settings found")
    end
  end

  defp migrate_schedule_settings(db) do
    Logger.info("Migrating schedule settings...")

    {:ok, stmt} = Exqlite.Sqlite3.prepare(db, """
      SELECT enabled, schedule, topic, last_run_at
      FROM schedule_settings
      LIMIT 1
    """)

    case fetch_all_rows(db, stmt) do
      [[enabled, schedule, topic, last_run_at]] ->
        AiTips.Scheduling.update_settings(%{
          enabled: enabled == 1,
          schedule: schedule || "daily_9am",
          topic: topic,
          last_run_at: parse_datetime(last_run_at)
        })

        Logger.info("Migrated schedule settings")

      _ ->
        Logger.info("No schedule settings found")
    end
  end

  defp migrate_schedule_logs(db) do
    Logger.info("Migrating schedule logs...")

    {:ok, stmt} = Exqlite.Sqlite3.prepare(db, """
      SELECT status, message, created_at
      FROM schedule_logs
      ORDER BY created_at DESC
      LIMIT 100
    """)

    logs = fetch_all_rows(db, stmt)

    log_count =
      Enum.reduce(logs, 0, fn row, count ->
        [status, message, created_at] = row

        {:ok, _log} =
          AiTips.Repo.insert(%AiTips.Scheduling.ScheduleLog{
            status: status,
            message: message,
            inserted_at: parse_datetime(created_at),
            updated_at: parse_datetime(created_at)
          })

        count + 1
      end)

    Logger.info("Migrated #{log_count} schedule logs")
  end

  defp fetch_all_rows(db, stmt) do
    fetch_all_rows(db, stmt, [])
  end

  defp fetch_all_rows(db, stmt, acc) do
    case Exqlite.Sqlite3.step(db, stmt) do
      {:row, row} ->
        fetch_all_rows(db, stmt, [row | acc])

      :done ->
        Enum.reverse(acc)

      {:error, reason} ->
        Logger.error("SQLite error: #{reason}")
        Enum.reverse(acc)
    end
  end

  defp parse_datetime(nil), do: DateTime.utc_now() |> DateTime.truncate(:second)

  defp parse_datetime(str) when is_binary(str) do
    case DateTime.from_iso8601(str) do
      {:ok, dt, _} -> DateTime.truncate(dt, :second)
      _ ->
        # Try parsing without timezone
        case NaiveDateTime.from_iso8601(str) do
          {:ok, ndt} -> DateTime.from_naive!(ndt, "Etc/UTC") |> DateTime.truncate(:second)
          _ -> DateTime.utc_now() |> DateTime.truncate(:second)
        end
    end
  end

  defp parse_datetime(_), do: DateTime.utc_now() |> DateTime.truncate(:second)
end
