defmodule SkillsetEvaluator.LLM.TestProvider do
  @moduledoc """
  A deterministic LLM provider used in tests.
  Returns fixed responses so no external API calls are made.
  """
  @behaviour SkillsetEvaluator.LLM.Provider

  def chat(_messages, _opts) do
    {:ok,
     %{
       content: "Test response from LLM.",
       token_usage: %{input: 10, output: 20},
       model: "claude-test"
     }}
  end

  # Returning :error forces the controller to fall back to non-streaming chat/2
  def stream(_messages, _opts), do: {:error, :streaming_not_supported_in_tests}

  def name, do: "test"
end
