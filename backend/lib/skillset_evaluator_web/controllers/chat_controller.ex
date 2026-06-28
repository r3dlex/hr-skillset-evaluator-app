defmodule SkillsetEvaluatorWeb.ChatController do
  use SkillsetEvaluatorWeb, :controller

  alias SkillsetEvaluator.Chat
  alias SkillsetEvaluator.LLM.{ContextBuilder, Guardrails, RateLimiter, Router, Stream}

  require Logger

  ## REST actions

  @doc """
  GET /api/chat/conversations - list own conversations, optionally filtered by search query
  """
  def index(conn, params) do
    user = conn.assigns.current_user
    limit = Map.get(params, "limit", "20") |> String.to_integer()
    offset = Map.get(params, "offset", "0") |> String.to_integer()

    case Map.get(params, "q") do
      nil ->
        conversations = Chat.list_conversations(user.id, limit: limit, offset: offset)
        render(conn, :index, conversations: conversations)

      "" ->
        conversations = Chat.list_conversations(user.id, limit: limit, offset: offset)
        render(conn, :index, conversations: conversations)

      query ->
        results = Chat.search_conversations(user.id, query, limit: limit)
        render(conn, :search, results: results)
    end
  end

  @doc """
  POST /api/chat/conversations - create new conversation
  """
  def create(conn, params) do
    user = conn.assigns.current_user

    attrs = %{
      title: Map.get(params, "title"),
      locale: Map.get(params, "locale", "en")
    }

    case Chat.create_conversation(user.id, attrs) do
      {:ok, conversation} ->
        conn
        |> put_status(:created)
        |> render(:created, conversation: conversation)

      {:error, :conversation_limit_reached} ->
        conn
        |> put_status(:too_many_requests)
        |> json(%{error: "Conversation limit reached (max 50). Please delete old conversations."})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: format_changeset_errors(changeset)})
    end
  end

  @doc """
  GET /api/chat/conversations/:id - get conversation with messages
  """
  def show(conn, %{"id" => id}) do
    user = conn.assigns.current_user

    case Chat.get_conversation(id) do
      nil ->
        conn |> put_status(:not_found) |> json(%{error: "Conversation not found"})

      conversation ->
        if conversation.user_id != user.id do
          conn |> put_status(:forbidden) |> json(%{error: "Access denied"})
        else
          render(conn, :show, conversation: conversation)
        end
    end
  end

  @doc """
  DELETE /api/chat/conversations/:id - delete own conversation
  """
  def delete(conn, %{"id" => id}) do
    user = conn.assigns.current_user

    case Chat.get_conversation(id) do
      nil ->
        conn |> put_status(:not_found) |> json(%{error: "Conversation not found"})

      conversation ->
        if conversation.user_id != user.id do
          conn |> put_status(:forbidden) |> json(%{error: "Access denied"})
        else
          {:ok, _} = Chat.delete_conversation(conversation)
          conn |> put_status(:ok) |> json(%{message: "Conversation deleted"})
        end
    end
  end

  @doc """
  POST /api/chat/conversations/:id/messages - send message, get AI response via SSE stream
  """
  def send_message(conn, %{"id" => conversation_id, "content" => content} = params) do
    user = conn.assigns.current_user
    screen_context = Map.get(params, "screen_context", %{})

    with {:conv, conversation} when not is_nil(conversation) <-
           {:conv, Chat.get_conversation(conversation_id)},
         {:owner, true} <- {:owner, conversation.user_id == user.id},
         :ok <- Guardrails.validate_input(content),
         :ok <- RateLimiter.check_rate(user.id, user.role) do
      # Save user message
      {:ok, _user_msg} =
        Chat.create_message(conversation_id, %{
          role: "user",
          content: content
        })

      # Auto-title conversation from first message
      Chat.maybe_auto_title(conversation_id, content)

      # Build context with screen awareness
      system_prompt = ContextBuilder.build_system_prompt(user, screen_context)
      messages = ContextBuilder.build_messages(conversation_id)

      # Get provider
      locale = conversation.locale || "en"
      provider = Router.get_provider(locale)

      # Try streaming first, fall back to non-streaming
      stream_response(conn, provider, system_prompt, messages, conversation_id, user)
    else
      {:conv, nil} ->
        conn |> put_status(:not_found) |> json(%{error: "Conversation not found"})

      {:owner, false} ->
        conn |> put_status(:forbidden) |> json(%{error: "Access denied"})

      {:error, reason} when is_binary(reason) ->
        conn |> put_status(:bad_request) |> json(%{error: reason})

      {:error, :rate_limited, retry_after} ->
        conn
        |> put_resp_header("retry-after", to_string(retry_after))
        |> put_status(:too_many_requests)
        |> json(%{error: "Rate limited", retry_after: retry_after})
    end
  end

  def send_message(conn, _params) do
    conn |> put_status(:bad_request) |> json(%{error: "Missing required parameter: content"})
  end

  ## SSE Streaming

  defp stream_response(conn, provider, system_prompt, messages, conversation_id, user) do
    case provider.stream(messages, system: system_prompt) do
      {:ok, stream_config} ->
        do_sse_stream(conn, stream_config, provider, conversation_id, user)

      {:error, _reason} ->
        non_streaming_response(conn, provider, system_prompt, messages, conversation_id, user)
    end
  end

  defp do_sse_stream(conn, stream_config, provider, conversation_id, user) do
    conn =
      conn
      |> put_resp_content_type("text/event-stream")
      |> put_resp_header("cache-control", "no-cache")
      |> put_resp_header("connection", "keep-alive")
      |> put_resp_header("x-accel-buffering", "no")
      |> send_chunked(200)

    case Stream.run(conn, stream_config) do
      {:ok, full_content, token_usage} ->
        {:ok, cleaned_content} = Guardrails.validate_output(full_content, user)

        {:ok, assistant_msg} =
          Chat.create_message(conversation_id, %{
            role: "assistant",
            content: cleaned_content,
            token_usage: token_usage,
            provider: provider.name(),
            model: token_usage[:model] || "unknown"
          })

        done_data =
          Jason.encode!(%{
            message_id: assistant_msg.id,
            token_usage: token_usage
          })

        chunk(conn, "event: done\ndata: #{done_data}\n\n")
        conn

      {:error, reason} ->
        error_data = Jason.encode!(Stream.format_error(stream_config, reason))
        chunk(conn, "event: error\ndata: #{error_data}\n\n")
        conn
    end
  end

  ## Non-streaming fallback

  defp non_streaming_response(conn, provider, system_prompt, messages, conversation_id, user) do
    case provider.chat(messages, system: system_prompt) do
      {:ok, %{content: content, token_usage: token_usage, model: model}} ->
        # Validate output
        {:ok, cleaned_content} = Guardrails.validate_output(content, user)

        # Save assistant message
        {:ok, assistant_msg} =
          Chat.create_message(conversation_id, %{
            role: "assistant",
            content: cleaned_content,
            token_usage: token_usage,
            provider: provider.name(),
            model: model
          })

        render(conn, :message, message: assistant_msg)

      {:error, reason} ->
        conn
        |> put_status(:bad_gateway)
        |> json(%{error: "LLM request failed: #{reason}"})
    end
  end

  ## Helpers

  defp format_changeset_errors(%Ecto.Changeset{} = changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
    |> Enum.map(fn {field, errors} -> "#{field}: #{Enum.join(errors, ", ")}" end)
    |> Enum.join("; ")
  end

  defp format_changeset_errors(error), do: inspect(error)

  @doc """
  POST /api/chat/conversations/:id/upload - upload xlsx file for AI-triggered import.
  Manager/Admin only (enforced by router scope).
  Returns a file_ref that the AI import_xlsx tool can use.
  """
  def upload(conn, %{"id" => conversation_id, "file" => %Plug.Upload{} = upload}) do
    user = conn.assigns.current_user

    # Verify conversation exists and belongs to user
    case Chat.get_conversation(conversation_id) do
      nil ->
        conn |> put_status(:not_found) |> json(%{error: "Conversation not found"})

      conversation when conversation.user_id != user.id ->
        conn |> put_status(:not_found) |> json(%{error: "Conversation not found"})

      _conversation ->
        # Validate file extension
        if String.ends_with?(upload.filename, ".xlsx") do
          file_ref = Ecto.UUID.generate()
          dest = Path.join(System.tmp_dir!(), "chat_upload_#{file_ref}.xlsx")
          File.cp!(upload.path, dest)

          conn
          |> put_status(:ok)
          |> json(%{
            data: %{
              file_ref: file_ref,
              filename: upload.filename,
              size: File.stat!(dest).size
            }
          })
        else
          conn |> put_status(:bad_request) |> json(%{error: "Only .xlsx files are supported"})
        end
    end
  end

  def upload(conn, _params) do
    conn |> put_status(:bad_request) |> json(%{error: "Missing file upload"})
  end
end
