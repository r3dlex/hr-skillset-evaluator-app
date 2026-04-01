defmodule SkillsetEvaluator.LLM.MiniMaxTest do
  use ExUnit.Case, async: true

  alias SkillsetEvaluator.LLM.MiniMax

  describe "name/0" do
    test "returns 'minimax'" do
      assert MiniMax.name() == "minimax"
    end
  end

  describe "stream/2" do
    test "returns error because streaming is not implemented" do
      result = MiniMax.stream([%{role: "user", content: "Hello"}], [])
      assert {:error, msg} = result
      assert is_binary(msg)
      assert String.contains?(String.downcase(msg), "stream")
    end
  end

  describe "chat/2" do
    test "returns error when MINIMAX_API_KEY is not set" do
      original_key = System.get_env("MINIMAX_API_KEY")
      original_group = System.get_env("MINIMAX_GROUP_ID")
      System.delete_env("MINIMAX_API_KEY")
      System.delete_env("MINIMAX_GROUP_ID")

      on_exit(fn ->
        if original_key, do: System.put_env("MINIMAX_API_KEY", original_key)
        if original_group, do: System.put_env("MINIMAX_GROUP_ID", original_group)
      end)

      messages = [%{role: "user", content: "Hello"}]
      result = MiniMax.chat(messages, [])
      assert {:error, msg} = result
      assert String.contains?(msg, "MiniMax not configured")
    end

    test "returns error when only MINIMAX_API_KEY is set but not GROUP_ID" do
      original_key = System.get_env("MINIMAX_API_KEY")
      original_group = System.get_env("MINIMAX_GROUP_ID")
      System.put_env("MINIMAX_API_KEY", "test-key")
      System.delete_env("MINIMAX_GROUP_ID")

      on_exit(fn ->
        if original_key,
          do: System.put_env("MINIMAX_API_KEY", original_key),
          else: System.delete_env("MINIMAX_API_KEY")

        if original_group, do: System.put_env("MINIMAX_GROUP_ID", original_group)
      end)

      messages = [%{role: "user", content: "Hello"}]
      result = MiniMax.chat(messages, [])
      assert {:error, msg} = result
      assert String.contains?(msg, "MiniMax not configured")
    end

    test "returns error when only MINIMAX_GROUP_ID is set but not API_KEY" do
      original_key = System.get_env("MINIMAX_API_KEY")
      original_group = System.get_env("MINIMAX_GROUP_ID")
      System.delete_env("MINIMAX_API_KEY")
      System.put_env("MINIMAX_GROUP_ID", "test-group")

      on_exit(fn ->
        if original_key, do: System.put_env("MINIMAX_API_KEY", original_key)

        if original_group,
          do: System.put_env("MINIMAX_GROUP_ID", original_group),
          else: System.delete_env("MINIMAX_GROUP_ID")
      end)

      messages = [%{role: "user", content: "Hello"}]
      result = MiniMax.chat(messages, [])
      assert {:error, msg} = result
      assert String.contains?(msg, "MiniMax not configured")
    end
  end
end
