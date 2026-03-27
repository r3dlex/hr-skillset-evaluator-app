defmodule SkillsetEvaluatorWeb.ChatController do
  use SkillsetEvaluatorWeb, :controller

  alias SkillsetEvaluator.Chat
  alias SkillsetEvaluator.LLM.{ContextBuilder, Guardrails, RateLimiter, Router}

  require Logger

  ## REST actions

  @doc """
  GET /api/chat/conversations — list own conversations, optionally filtered by search query
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
  POST /api/chat/conversations — create new conversation
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
  GET /api/chat/conversations/:id — get conversation with messages
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
  DELETE /api/chat/conversations/:id — delete own conversation
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
  POST /api/chat/conversations/:id/messages — send message, get AI response via SSE stream
  """
  def send_message(conn, %{"id" => conversation_id, "content" => content}) do
    user = conn.assigns.current_user

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

      # Build context
      system_prompt = ContextBuilder.build_system_prompt(user)
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
        # Fall back to non-streaming
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

    # Make the streaming request to Anthropic
    accumulated = do_anthropic_stream(conn, stream_config)

    case accumulated do
      {:ok, full_content, token_usage} ->
        # Validate output
        {:ok, cleaned_content} = Guardrails.validate_output(full_content, user.role)

        # Save assistant message
        {:ok, assistant_msg} =
          Chat.create_message(conversation_id, %{
            role: "assistant",
            content: cleaned_content,
            token_usage: token_usage,
            provider: provider.name(),
            model: token_usage[:model] || "unknown"
          })

        # Send done event
        done_data =
          Jason.encode!(%{
            message_id: assistant_msg.id,
            token_usage: token_usage
          })

        chunk(conn, "event: done\ndata: #{done_data}\n\n")
        conn

      {:error, reason} ->
        {code, message, retryable} = classify_error(reason)
        error_data = Jason.encode!(%{code: code, message: message, retryable: retryable})
        chunk(conn, "event: error\ndata: #{error_data}\n\n")
        conn
    end
  end

  # Maps API status codes and error types to user-friendly messages
  @anthropic_errors %{
    400 =>
      {"invalid_request", "The request was malformed. Please try rephrasing your message.", false},
    401 =>
      {"authentication_error",
       "The AI service credentials are invalid. Please contact your administrator.", false},
    403 =>
      {"permission_denied",
       "Access to the AI service is denied. Please contact your administrator.", false},
    404 =>
      {"not_found",
       "The AI service endpoint could not be reached. Please check the configuration.", false},
    408 => {"request_timeout", "The request timed out. Please try again.", true},
    429 =>
      {"rate_limit_error",
       "The AI service is temporarily overloaded. Please wait a moment and try again.", true},
    500 =>
      {"api_error", "The AI service encountered an internal error. Please try again later.", true},
    502 =>
      {"bad_gateway",
       "The AI service is temporarily unavailable. Please try again in a few moments.", true},
    503 =>
      {"overloaded", "The AI service is currently overloaded. Please try again in a few minutes.",
       true},
    529 =>
      {"overloaded", "The AI service is currently overloaded. Please try again in a few minutes.",
       true}
  }

  defp classify_error(reason) when is_binary(reason) do
    cond do
      String.contains?(reason, "status 4") or String.contains?(reason, "status 5") ->
        # Extract status code from "API returned status XXX" or "API error: XXX"
        case Regex.run(~r/(\d{3})/, reason) do
          [_, code_str] ->
            code = String.to_integer(code_str)
            Map.get(@anthropic_errors, code, {"api_error", reason, code >= 500})

          _ ->
            {"api_error", reason, false}
        end

      String.contains?(reason, "timeout") ->
        {"request_timeout", "The AI service took too long to respond. Please try again.", true}

      String.contains?(reason, "connection") or String.contains?(reason, "nxdomain") ->
        {"connection_error",
         "Could not connect to the AI service. Please check your network connection.", true}

      true ->
        {"stream_error", reason, false}
    end
  end

  defp classify_error(reason), do: {"stream_error", inspect(reason), false}

  defp do_anthropic_stream(conn, %{url: url, headers: headers, body: body}) do
    # Use Req with into: :self for streaming
    parent = self()

    task =
      Task.async(fn ->
        result =
          Req.post(url,
            json: body,
            headers: headers,
            receive_timeout: 120_000,
            into: fn {:data, data}, {req, resp} ->
              send(parent, {:sse_chunk, data})
              {:cont, {req, resp}}
            end
          )

        # Notify parent about completion status with error details
        case result do
          {:ok, %{status: status, body: body}} when status != 200 ->
            error_msg = extract_api_error(status, body)
            send(parent, {:stream_error, error_msg})

          {:error, %{reason: reason}} ->
            send(parent, {:stream_error, "connection error: #{inspect(reason)}"})

          {:error, reason} ->
            send(parent, {:stream_error, inspect(reason)})

          _ ->
            :ok
        end

        result
      end)

    # Collect chunks and forward deltas
    result = collect_sse_chunks(conn, "", %{}, task)
    # Task already completed by the time collect_sse_chunks returns
    Process.demonitor(task.ref, [:flush])
    result
  rescue
    e ->
      Logger.error("SSE stream error: #{inspect(e)}")
      {:error, "Streaming failed"}
  end

  defp collect_sse_chunks(conn, accumulated, token_usage, task) do
    receive do
      {:sse_chunk, data} ->
        {new_text, new_usage} = parse_anthropic_sse(data, token_usage)

        if new_text != "" do
          delta_data = Jason.encode!(%{content: new_text})
          chunk(conn, "event: delta\ndata: #{delta_data}\n\n")
        end

        collect_sse_chunks(conn, accumulated <> new_text, new_usage, task)

      {:stream_error, reason} ->
        Logger.error("LLM stream error: #{reason}")
        {:error, reason}

      {ref, _result} when is_reference(ref) ->
        # Task completed
        if accumulated == "" do
          {:error, "No response from LLM provider"}
        else
          {:ok, accumulated, token_usage}
        end

      {:DOWN, _ref, :process, _pid, _reason} ->
        {:ok, accumulated, token_usage}
    after
      120_000 ->
        {:error, "Stream timeout"}
    end
  end

  defp parse_anthropic_sse(data, token_usage) do
    # Anthropic sends SSE formatted data, potentially multiple events in one chunk
    lines = String.split(data, "\n")

    {text, usage} =
      Enum.reduce(lines, {"", token_usage}, fn line, {text_acc, usage_acc} ->
        cond do
          String.starts_with?(line, "data: ") ->
            json_str = String.trim_leading(line, "data: ")

            case Jason.decode(json_str) do
              {:ok, %{"type" => "content_block_delta", "delta" => %{"text" => delta_text}}} ->
                {text_acc <> delta_text, usage_acc}

              {:ok, %{"type" => "message_delta", "usage" => usage}} ->
                new_usage =
                  Map.merge(usage_acc, %{
                    output: usage["output_tokens"] || Map.get(usage_acc, :output, 0)
                  })

                {text_acc, new_usage}

              {:ok, %{"type" => "message_start", "message" => %{"usage" => usage}}} ->
                new_usage =
                  Map.merge(usage_acc, %{
                    input: usage["input_tokens"] || 0,
                    model: usage["model"]
                  })

                {text_acc, new_usage}

              _ ->
                {text_acc, usage_acc}
            end

          true ->
            {text_acc, usage_acc}
        end
      end)

    {text, usage}
  end

  ## Non-streaming fallback

  defp non_streaming_response(conn, provider, system_prompt, messages, conversation_id, user) do
    case provider.chat(messages, system: system_prompt) do
      {:ok, %{content: content, token_usage: token_usage, model: model}} ->
        # Validate output
        {:ok, cleaned_content} = Guardrails.validate_output(content, user.role)

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

  defp extract_api_error(status, body) when is_binary(body) do
    case Jason.decode(body) do
      {:ok, %{"error" => %{"message" => msg}}} ->
        "API error status #{status}: #{msg}"

      {:ok, %{"error" => %{"type" => type}}} ->
        "API error status #{status}: #{type}"

      _ ->
        "API returned status #{status}"
    end
  end

  defp extract_api_error(status, body) when is_map(body) do
    case body do
      %{"error" => %{"message" => msg}} -> "API error status #{status}: #{msg}"
      %{"error" => %{"type" => type}} -> "API error status #{status}: #{type}"
      _ -> "API returned status #{status}"
    end
  end

  defp extract_api_error(status, _body), do: "API returned status #{status}"
end
