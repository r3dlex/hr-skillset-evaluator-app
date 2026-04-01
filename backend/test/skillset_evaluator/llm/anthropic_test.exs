defmodule SkillsetEvaluator.LLM.AnthropicTest do
  use ExUnit.Case, async: true

  alias SkillsetEvaluator.LLM.Anthropic

  describe "name/0" do
    test "returns 'anthropic'" do
      assert Anthropic.name() == "anthropic"
    end
  end

  describe "stream/2" do
    test "returns ok tuple with url, headers, and body when api key is set" do
      original = Application.get_env(:skillset_evaluator, :anthropic_api_key)
      Application.put_env(:skillset_evaluator, :anthropic_api_key, "test-key-123")

      on_exit(fn ->
        if original do
          Application.put_env(:skillset_evaluator, :anthropic_api_key, original)
        else
          Application.delete_env(:skillset_evaluator, :anthropic_api_key)
        end
      end)

      messages = [%{role: "user", content: "Hello"}]
      result = Anthropic.stream(messages, [])

      assert {:ok, config} = result
      assert Map.has_key?(config, :url)
      assert Map.has_key?(config, :headers)
      assert Map.has_key?(config, :body)
      assert is_binary(config.url)
      assert is_list(config.headers)
      assert is_map(config.body)
    end

    test "stream includes system in body when provided" do
      Application.put_env(:skillset_evaluator, :anthropic_api_key, "test-key")

      on_exit(fn ->
        Application.delete_env(:skillset_evaluator, :anthropic_api_key)
      end)

      messages = [%{role: "user", content: "Hello"}]
      {:ok, config} = Anthropic.stream(messages, system: "You are a helpful assistant")

      assert Map.get(config.body, :system) == "You are a helpful assistant"
    end

    test "stream body includes stream: true flag" do
      Application.put_env(:skillset_evaluator, :anthropic_api_key, "test-key")

      on_exit(fn ->
        Application.delete_env(:skillset_evaluator, :anthropic_api_key)
      end)

      {:ok, config} = Anthropic.stream([%{role: "user", content: "Hi"}], [])
      assert config.body[:stream] == true
    end

    test "stream filters out system messages from messages array" do
      Application.put_env(:skillset_evaluator, :anthropic_api_key, "test-key")

      on_exit(fn ->
        Application.delete_env(:skillset_evaluator, :anthropic_api_key)
      end)

      messages = [
        %{role: "system", content: "System prompt"},
        %{role: "user", content: "Hello"},
        %{role: "assistant", content: "Hi"}
      ]

      {:ok, config} = Anthropic.stream(messages, [])
      # system messages should be filtered out of the messages array
      roles = Enum.map(config.body[:messages], & &1.role)
      refute "system" in roles
    end

    test "stream uses configured model when provided" do
      Application.put_env(:skillset_evaluator, :anthropic_api_key, "test-key")

      on_exit(fn ->
        Application.delete_env(:skillset_evaluator, :anthropic_api_key)
      end)

      {:ok, config} = Anthropic.stream([%{role: "user", content: "Hi"}], model: "claude-test-v1")
      assert config.body[:model] == "claude-test-v1"
    end

    test "stream raises when api key is not configured" do
      # Remove all possible key sources
      original_env = Application.get_env(:skillset_evaluator, :anthropic_api_key)
      Application.delete_env(:skillset_evaluator, :anthropic_api_key)
      original_sys = System.get_env("ANTHROPIC_API_KEY")
      System.delete_env("ANTHROPIC_API_KEY")

      on_exit(fn ->
        if original_env, do: Application.put_env(:skillset_evaluator, :anthropic_api_key, original_env)
        if original_sys, do: System.put_env("ANTHROPIC_API_KEY", original_sys)
      end)

      assert_raise RuntimeError, ~r/ANTHROPIC_API_KEY/, fn ->
        Anthropic.stream([%{role: "user", content: "test"}], [])
      end
    end
  end

  describe "chat/2" do
    test "raises when api key is not configured" do
      original_env = Application.get_env(:skillset_evaluator, :anthropic_api_key)
      Application.delete_env(:skillset_evaluator, :anthropic_api_key)
      original_sys = System.get_env("ANTHROPIC_API_KEY")
      System.delete_env("ANTHROPIC_API_KEY")

      on_exit(fn ->
        if original_env, do: Application.put_env(:skillset_evaluator, :anthropic_api_key, original_env)
        if original_sys, do: System.put_env("ANTHROPIC_API_KEY", original_sys)
      end)

      assert_raise RuntimeError, ~r/ANTHROPIC_API_KEY/, fn ->
        Anthropic.chat([%{role: "user", content: "test"}], [])
      end
    end
  end
end
