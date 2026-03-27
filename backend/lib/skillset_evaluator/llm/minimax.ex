defmodule SkillsetEvaluator.LLM.MiniMax do
  @moduledoc """
  MiniMax LLM provider implementation (for Chinese locale).
  """

  @behaviour SkillsetEvaluator.LLM.Provider

  require Logger

  @default_api_url "https://api.minimax.chat/v1/text/chatcompletion_v2"

  defp api_url do
    Application.get_env(:skillset_evaluator, :minimax_base_url) ||
      System.get_env("MINIMAX_BASE_URL") ||
      @default_api_url
  end

  @impl true
  def name, do: "minimax"

  @impl true
  def chat(messages, opts \\ []) do
    api_key = System.get_env("MINIMAX_API_KEY")
    group_id = System.get_env("MINIMAX_GROUP_ID")

    if is_nil(api_key) || is_nil(group_id) do
      {:error, "MiniMax not configured. Set MINIMAX_API_KEY and MINIMAX_GROUP_ID."}
    else
      model = Keyword.get(opts, :model, "MiniMax-Text-01")
      max_tokens = Keyword.get(opts, :max_tokens, 2048)
      system = Keyword.get(opts, :system, nil)

      mm_messages = format_messages(messages, system)

      case Req.post("#{api_url()}?GroupId=#{group_id}",
             json: %{model: model, messages: mm_messages, tokens_to_generate: max_tokens},
             headers: [{"Authorization", "Bearer #{api_key}"}],
             receive_timeout: 60_000
           ) do
        {:ok, %{status: 200, body: resp}} ->
          content = get_in(resp, ["choices", Access.at(0), "message", "content"]) || ""
          usage = resp["usage"] || %{}

          {:ok,
           %{
             content: content,
             token_usage: %{
               input: usage["prompt_tokens"] || 0,
               output: usage["completion_tokens"] || 0
             },
             model: model
           }}

        {:ok, %{status: status, body: body}} ->
          {:error, "MiniMax API error: #{status} - #{inspect(body)}"}

        {:error, reason} ->
          {:error, "MiniMax API request failed: #{inspect(reason)}"}
      end
    end
  end

  @impl true
  def stream(_messages, _opts) do
    {:error, "MiniMax streaming not yet implemented"}
  end

  defp format_messages(messages, system) do
    sys = if system, do: [%{role: "system", content: system}], else: []

    user_msgs =
      Enum.map(messages, fn msg ->
        %{role: msg[:role] || msg["role"], content: msg[:content] || msg["content"]}
      end)

    sys ++ user_msgs
  end
end
