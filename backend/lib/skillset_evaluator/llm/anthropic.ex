defmodule SkillsetEvaluator.LLM.Anthropic do
  @moduledoc """
  Anthropic Claude LLM provider implementation.
  """

  @behaviour SkillsetEvaluator.LLM.Provider

  require Logger

  @default_api_url "https://api.anthropic.com/v1/messages"
  @default_model "claude-sonnet-4-20250514"

  defp api_url do
    Application.get_env(:skillset_evaluator, :anthropic_base_url) ||
      System.get_env("ANTHROPIC_BASE_URL") ||
      @default_api_url
  end

  defp model do
    Application.get_env(:skillset_evaluator, :anthropic_model) ||
      System.get_env("ANTHROPIC_MODEL") ||
      @default_model
  end

  @impl true
  def name, do: "anthropic"

  @impl true
  def chat(messages, opts \\ []) do
    api_key = get_api_key()
    selected_model = Keyword.get(opts, :model, model())
    max_tokens = Keyword.get(opts, :max_tokens, 2048)
    temperature = Keyword.get(opts, :temperature, 0.3)
    system = Keyword.get(opts, :system, nil)

    body =
      %{
        model: selected_model,
        max_tokens: max_tokens,
        temperature: temperature,
        messages: format_messages(messages)
      }

    body = if system, do: Map.put(body, :system, system), else: body

    case Req.post(api_url(),
           json: body,
           headers: [
             {"x-api-key", api_key},
             {"anthropic-version", "2023-06-01"},
             {"content-type", "application/json"}
           ],
           receive_timeout: 60_000
         ) do
      {:ok, %{status: 200, body: resp}} ->
        content = resp["content"] |> List.first() |> Map.get("text", "")
        usage = resp["usage"] || %{}

        {:ok,
         %{
           content: content,
           token_usage: %{
             input: usage["input_tokens"] || 0,
             output: usage["output_tokens"] || 0
           },
           model: resp["model"] || selected_model
         }}

      {:ok, %{status: status, body: body}} ->
        Logger.error("Anthropic API error: #{status} - #{inspect(body)}")
        {:error, "LLM API error: #{status}"}

      {:error, reason} ->
        Logger.error("Anthropic API request failed: #{inspect(reason)}")
        {:error, "LLM API request failed"}
    end
  end

  @impl true
  def stream(messages, opts \\ []) do
    api_key = get_api_key()
    selected_model = Keyword.get(opts, :model, model())
    max_tokens = Keyword.get(opts, :max_tokens, 2048)
    temperature = Keyword.get(opts, :temperature, 0.3)
    system = Keyword.get(opts, :system, nil)

    body =
      %{
        model: selected_model,
        max_tokens: max_tokens,
        temperature: temperature,
        stream: true,
        messages: format_messages(messages)
      }

    body = if system, do: Map.put(body, :system, system), else: body

    {:ok,
     %{
       url: api_url(),
       headers: [
         {"x-api-key", api_key},
         {"anthropic-version", "2023-06-01"},
         {"content-type", "application/json"}
       ],
       body: body
     }}
  end

  defp format_messages(messages) do
    messages
    |> Enum.map(fn msg ->
      %{role: msg[:role] || msg["role"], content: msg[:content] || msg["content"]}
    end)
    |> Enum.filter(fn msg -> msg.role in ["user", "assistant"] end)
  end

  defp get_api_key do
    Application.get_env(:skillset_evaluator, :anthropic_api_key) ||
      System.get_env("ANTHROPIC_API_KEY") ||
      raise "ANTHROPIC_API_KEY not configured"
  end
end
