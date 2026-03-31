defmodule SkillsetEvaluator.LLM.RouterTest do
  use ExUnit.Case, async: false

  alias SkillsetEvaluator.LLM.{Router, Anthropic, MiniMax, TestProvider}

  describe "get_provider/1" do
    test "returns TestProvider when configured as 'test'" do
      Application.put_env(:skillset_evaluator, :llm_provider, "test")
      assert Router.get_provider("en") == TestProvider
    after
      Application.put_env(:skillset_evaluator, :llm_provider, "test")
    end

    test "returns Anthropic for 'anthropic' setting" do
      Application.put_env(:skillset_evaluator, :llm_provider, "anthropic")
      assert Router.get_provider("en") == Anthropic
    after
      Application.put_env(:skillset_evaluator, :llm_provider, "test")
    end

    test "returns MiniMax for 'minimax' setting" do
      Application.put_env(:skillset_evaluator, :llm_provider, "minimax")
      assert Router.get_provider("en") == MiniMax
    after
      Application.put_env(:skillset_evaluator, :llm_provider, "test")
    end

    test "returns Anthropic for unknown setting" do
      Application.put_env(:skillset_evaluator, :llm_provider, "unknown_provider")
      assert Router.get_provider("en") == Anthropic
    after
      Application.put_env(:skillset_evaluator, :llm_provider, "test")
    end

    test "defaults to Anthropic for 'auto' without MiniMax env vars" do
      Application.put_env(:skillset_evaluator, :llm_provider, "auto")
      # Without MINIMAX_API_KEY and MINIMAX_GROUP_ID, falls back to Anthropic
      System.delete_env("MINIMAX_API_KEY")
      System.delete_env("MINIMAX_GROUP_ID")
      assert Router.get_provider("zh") == Anthropic
    after
      Application.put_env(:skillset_evaluator, :llm_provider, "test")
    end

    test "returns Anthropic for 'auto' + english locale" do
      Application.put_env(:skillset_evaluator, :llm_provider, "auto")
      System.put_env("MINIMAX_API_KEY", "key")
      System.put_env("MINIMAX_GROUP_ID", "group")
      assert Router.get_provider("en") == Anthropic
    after
      Application.put_env(:skillset_evaluator, :llm_provider, "test")
      System.delete_env("MINIMAX_API_KEY")
      System.delete_env("MINIMAX_GROUP_ID")
    end

    test "returns MiniMax for 'auto' + zh locale when MiniMax is configured" do
      Application.put_env(:skillset_evaluator, :llm_provider, "auto")
      System.put_env("MINIMAX_API_KEY", "key")
      System.put_env("MINIMAX_GROUP_ID", "group")
      assert Router.get_provider("zh") == MiniMax
    after
      Application.put_env(:skillset_evaluator, :llm_provider, "test")
      System.delete_env("MINIMAX_API_KEY")
      System.delete_env("MINIMAX_GROUP_ID")
    end

    test "uses default 'en' locale when called without argument" do
      Application.put_env(:skillset_evaluator, :llm_provider, "test")
      assert Router.get_provider() == TestProvider
    after
      Application.put_env(:skillset_evaluator, :llm_provider, "test")
    end
  end
end
