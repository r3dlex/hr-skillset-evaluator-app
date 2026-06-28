defmodule SkillsetEvaluator.LLM.AnthropicStreamAdapter do
  @moduledoc """
  Anthropic-specific adapter for streaming SSE payloads and stream errors.
  """

  @behaviour SkillsetEvaluator.LLM.Stream

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

  @impl true
  def parse_chunk(data, token_usage) when is_binary(data) and is_map(token_usage) do
    data
    |> String.split("\n")
    |> Enum.reduce({"", token_usage}, &parse_line/2)
  end

  @impl true
  def format_error(reason) when is_binary(reason) do
    {code, message, retryable} = classify_error(reason)
    %{code: code, message: message, retryable: retryable}
  end

  def format_error(reason),
    do: %{code: "stream_error", message: inspect(reason), retryable: false}

  @impl true
  def extract_error(status, body) when is_binary(body) do
    case Jason.decode(body) do
      {:ok, %{"error" => %{"message" => message}}} ->
        "API error status #{status}: #{message}"

      {:ok, %{"error" => %{"type" => type}}} ->
        "API error status #{status}: #{type}"

      _ ->
        "API returned status #{status}"
    end
  end

  def extract_error(status, body) when is_map(body) do
    case body do
      %{"error" => %{"message" => message}} -> "API error status #{status}: #{message}"
      %{"error" => %{"type" => type}} -> "API error status #{status}: #{type}"
      _ -> "API returned status #{status}"
    end
  end

  def extract_error(status, _body), do: "API returned status #{status}"

  defp parse_line(line, {text_acc, usage_acc}) do
    if String.starts_with?(line, "data: ") do
      line
      |> String.trim_leading("data: ")
      |> parse_data(text_acc, usage_acc)
    else
      {text_acc, usage_acc}
    end
  end

  defp parse_data(json, text_acc, usage_acc) do
    case Jason.decode(json) do
      {:ok, %{"type" => "content_block_delta", "delta" => %{"text" => delta_text}}} ->
        {text_acc <> delta_text, usage_acc}

      {:ok, %{"type" => "message_delta", "usage" => usage}} ->
        {text_acc,
         Map.merge(usage_acc, %{
           output: usage["output_tokens"] || Map.get(usage_acc, :output, 0)
         })}

      {:ok, %{"type" => "message_start", "message" => message}} ->
        usage = message["usage"] || %{}

        {text_acc,
         Map.merge(usage_acc, %{
           input: usage["input_tokens"] || 0,
           model: message["model"] || usage["model"]
         })}

      _ ->
        {text_acc, usage_acc}
    end
  end

  defp classify_error(reason) do
    cond do
      String.contains?(reason, "status 4") or String.contains?(reason, "status 5") ->
        case Regex.run(~r/(\d{3})/, reason) do
          [_, code_string] ->
            code = String.to_integer(code_string)
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
end
