defmodule AiTipsWeb.AuthController do
  use AiTipsWeb, :controller

  require Logger

  alias AiTips.Accounts

  plug Ueberauth when action in [:request]

  @doc """
  Initiates the OAuth flow - handled by Ueberauth.
  """
  def request(conn, _params) do
    # Ueberauth handles this automatically
    conn
  end

  @doc """
  Handles the callback from Azure AD.
  Manually exchanges the code for tokens to avoid CSRF issues with ueberauth_azure_ad.
  """
  def callback(conn, %{"code" => code, "provider" => "azure_ad"}) do
    client_id = get_config(:client_id)
    client_secret = get_config(:client_secret)
    tenant_id = get_config(:tenant_id)
    redirect_uri = url(~p"/auth/azure_ad/callback")

    token_url = "https://login.microsoftonline.com/#{tenant_id}/oauth2/v2.0/token"

    body = %{
      grant_type: "authorization_code",
      client_id: client_id,
      client_secret: client_secret,
      code: code,
      redirect_uri: redirect_uri,
      scope: "openid profile email"
    }

    case Req.post(token_url, form: body) do
      {:ok, %{status: 200, body: token_response}} ->
        handle_token_response(conn, token_response)

      {:ok, %{status: status, body: error_body}} ->
        Logger.error("Azure AD token error: #{status} - #{inspect(error_body)}")
        conn
        |> put_flash(:error, "Authentication failed: could not get token")
        |> redirect(to: ~p"/login")

      {:error, reason} ->
        Logger.error("Azure AD token request failed: #{inspect(reason)}")
        conn
        |> put_flash(:error, "Authentication failed: #{inspect(reason)}")
        |> redirect(to: ~p"/login")
    end
  end

  def callback(conn, %{"error" => error, "error_description" => description}) do
    Logger.error("Azure AD auth error: #{error} - #{description}")
    conn
    |> put_flash(:error, "Authentication failed: #{description}")
    |> redirect(to: ~p"/login")
  end

  def callback(conn, params) do
    Logger.error("Unexpected callback params: #{inspect(params)}")
    conn
    |> put_flash(:error, "Authentication failed unexpectedly")
    |> redirect(to: ~p"/login")
  end

  defp handle_token_response(conn, %{"id_token" => id_token}) do
    # Decode the JWT to get user info (without verification for simplicity)
    # In production, you should verify the token signature
    case decode_jwt(id_token) do
      {:ok, claims} ->
        user_params = %{
          azure_uid: claims["oid"] || claims["sub"],
          email: claims["email"] || claims["preferred_username"],
          name: claims["name"] || claims["email"] || claims["preferred_username"]
        }

        Logger.info("Auth success - UID: #{user_params.azure_uid}, Email: #{user_params.email}")

        case Accounts.upsert_from_azure_ad(user_params) do
          {:ok, user} ->
            conn
            |> put_flash(:info, "Welcome, #{user.name}!")
            |> put_session(:user_id, user.id)
            |> configure_session(renew: true)
            |> redirect(to: ~p"/")

          {:error, changeset} ->
            errors = Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
              Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
                opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
              end)
            end)

            error_msg = errors |> Enum.map(fn {k, v} -> "#{k}: #{Enum.join(v, ", ")}" end) |> Enum.join("; ")

            conn
            |> put_flash(:error, "Authentication failed: #{error_msg}")
            |> redirect(to: ~p"/login")
        end

      {:error, reason} ->
        Logger.error("Failed to decode JWT: #{reason}")
        conn
        |> put_flash(:error, "Authentication failed: could not decode token")
        |> redirect(to: ~p"/login")
    end
  end

  defp handle_token_response(conn, response) do
    Logger.error("Unexpected token response: #{inspect(response)}")
    conn
    |> put_flash(:error, "Authentication failed: unexpected response")
    |> redirect(to: ~p"/login")
  end

  defp decode_jwt(token) do
    # JWT format: header.payload.signature
    case String.split(token, ".") do
      [_header, payload, _signature] ->
        case Base.url_decode64(payload, padding: false) do
          {:ok, json} ->
            {:ok, Jason.decode!(json)}

          :error ->
            {:error, "Invalid base64 encoding"}
        end

      _ ->
        {:error, "Invalid JWT format"}
    end
  end

  defp get_config(key) do
    Application.get_env(:ueberauth, Ueberauth.Strategy.AzureAD.OAuth)[key]
  end

  @doc """
  Logs the user out.
  """
  def logout(conn, _params) do
    conn
    |> put_flash(:info, "You have been logged out.")
    |> configure_session(drop: true)
    |> redirect(to: ~p"/login")
  end
end
