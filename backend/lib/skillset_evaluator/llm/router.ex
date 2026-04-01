defmodule SkillsetEvaluator.LLM.Router do
  @moduledoc """
  Routes LLM requests to the appropriate provider based on configuration and locale.
  """

  alias SkillsetEvaluator.LLM.{Anthropic, MiniMax}

  @doc """
  Returns the appropriate LLM provider module based on configuration and locale.
  """
  def get_provider(locale \\ "en") do
    case Application.get_env(:skillset_evaluator, :llm_provider_module) do
      nil ->
        case provider_setting() do
          "anthropic" -> Anthropic
          "minimax" -> MiniMax
          "test" -> SkillsetEvaluator.LLM.TestProvider
          "auto" -> if locale == "zh" && minimax_configured?(), do: MiniMax, else: Anthropic
          _ -> Anthropic
        end

      module ->
        module
    end
  end

  defp provider_setting do
    Application.get_env(:skillset_evaluator, :llm_provider) ||
      System.get_env("LLM_PROVIDER") || "anthropic"
  end

  defp minimax_configured? do
    System.get_env("MINIMAX_API_KEY") != nil && System.get_env("MINIMAX_GROUP_ID") != nil
  end
end
