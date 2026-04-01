defmodule SkillsetEvaluator.LLM.TestStreamingProvider do
  @moduledoc false
  @behaviour SkillsetEvaluator.LLM.Provider

  def name, do: "test_streaming"

  def chat(_messages, _opts) do
    {:ok, %{content: "streaming fallback", token_usage: %{input: 0, output: 0}, model: "test"}}
  end

  def stream(_messages, _opts) do
    case Application.get_env(:skillset_evaluator, :test_stream_config) do
      nil -> {:error, "no test stream config set"}
      config -> {:ok, config}
    end
  end
end
