defmodule SkillsetEvaluator.LLM.Provider do
  @moduledoc """
  Behaviour for LLM provider implementations.
  """

  @callback chat(messages :: list(map()), opts :: keyword()) ::
              {:ok, %{content: String.t(), token_usage: map(), model: String.t()}}
              | {:error, term()}

  @callback stream(messages :: list(map()), opts :: keyword()) ::
              {:ok, map()} | {:error, term()}

  @callback name() :: String.t()
end
