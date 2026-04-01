defmodule SkillsetEvaluator.LLM.MiniMaxTest do
  use ExUnit.Case, async: false

  alias SkillsetEvaluator.LLM.MiniMax

  setup do
    on_exit(fn ->
      Application.delete_env(:skillset_evaluator, :minimax_test_http)
    end)

    :ok
  end

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

  describe "chat/2 — missing config" do
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

  describe "chat/2 — with HTTP mock" do
    setup do
      original_key = System.get_env("MINIMAX_API_KEY")
      original_group = System.get_env("MINIMAX_GROUP_ID")
      System.put_env("MINIMAX_API_KEY", "test-minimax-key")
      System.put_env("MINIMAX_GROUP_ID", "test-group-id")

      on_exit(fn ->
        if original_key,
          do: System.put_env("MINIMAX_API_KEY", original_key),
          else: System.delete_env("MINIMAX_API_KEY")

        if original_group,
          do: System.put_env("MINIMAX_GROUP_ID", original_group),
          else: System.delete_env("MINIMAX_GROUP_ID")
      end)

      :ok
    end

    test "returns {:ok, result} on successful 200 response" do
      Application.put_env(:skillset_evaluator, :minimax_test_http, fn _url, _opts ->
        {:ok,
         %{
           status: 200,
           body: %{
             "choices" => [%{"message" => %{"content" => "Hello from MiniMax!"}}],
             "usage" => %{"prompt_tokens" => 8, "completion_tokens" => 6}
           }
         }}
      end)

      messages = [%{role: "user", content: "Hello"}]
      assert {:ok, result} = MiniMax.chat(messages, [])
      assert result.content == "Hello from MiniMax!"
      assert result.token_usage.input == 8
      assert result.token_usage.output == 6
    end

    test "passes system prompt as leading system message" do
      Application.put_env(:skillset_evaluator, :minimax_test_http, fn _url, opts ->
        body = Keyword.get(opts, :json)
        messages = body[:messages]
        assert hd(messages).role == "system"

        {:ok,
         %{
           status: 200,
           body: %{
             "choices" => [%{"message" => %{"content" => "OK"}}],
             "usage" => %{"prompt_tokens" => 1, "completion_tokens" => 1}
           }
         }}
      end)

      messages = [%{role: "user", content: "Hi"}]
      assert {:ok, _result} = MiniMax.chat(messages, system: "Be helpful", model: "custom-model")
    end

    test "returns {:error, reason} on non-200 response" do
      Application.put_env(:skillset_evaluator, :minimax_test_http, fn _url, _opts ->
        {:ok,
         %{
           status: 500,
           body: %{"base_resp" => %{"status_msg" => "Internal error"}}
         }}
      end)

      messages = [%{role: "user", content: "Hello"}]
      assert {:error, reason} = MiniMax.chat(messages, [])
      assert is_binary(reason)
      assert String.contains?(reason, "500")
    end

    test "returns {:error, reason} on connection failure" do
      Application.put_env(:skillset_evaluator, :minimax_test_http, fn _url, _opts ->
        {:error, "connection refused"}
      end)

      messages = [%{role: "user", content: "Hello"}]
      assert {:error, reason} = MiniMax.chat(messages, [])
      assert is_binary(reason)
      assert String.contains?(reason, "failed")
    end

    test "handles missing choices in response" do
      Application.put_env(:skillset_evaluator, :minimax_test_http, fn _url, _opts ->
        {:ok,
         %{
           status: 200,
           body: %{"choices" => [], "usage" => %{}}
         }}
      end)

      messages = [%{role: "user", content: "Hello"}]
      assert {:ok, result} = MiniMax.chat(messages, [])
      assert result.content == ""
      assert result.token_usage.input == 0
      assert result.token_usage.output == 0
    end
  end
end
