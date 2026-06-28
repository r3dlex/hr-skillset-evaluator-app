defmodule SkillsetEvaluator.LLM.StreamAdapterTest do
  use ExUnit.Case, async: true

  alias SkillsetEvaluator.LLM.{AnthropicStreamAdapter, Stream}

  describe "AnthropicStreamAdapter.parse_chunk/2" do
    test "extracts text deltas and token usage from Anthropic SSE chunks" do
      chunk =
        ~s'data: {"type":"message_start","message":{"model":"claude-test","usage":{"input_tokens":10}}}\n\n' <>
          ~s'data: {"type":"content_block_delta","delta":{"text":"Hello "}}\n\n' <>
          ~s'data: {"type":"content_block_delta","delta":{"text":"world"}}\n\n' <>
          ~s'data: {"type":"message_delta","usage":{"output_tokens":5}}\n\n'

      assert {"Hello world", %{input: 10, output: 5, model: "claude-test"}} =
               AnthropicStreamAdapter.parse_chunk(chunk, %{})
    end

    test "ignores non-data lines and malformed payloads" do
      chunk = "event: ping\ndata: not-json\n\n: keep-alive\n"

      assert {"", %{input: 1}} = AnthropicStreamAdapter.parse_chunk(chunk, %{input: 1})
    end
  end

  describe "AnthropicStreamAdapter.format_error/1" do
    test "maps provider status errors to compatible SSE error data" do
      assert %{code: "authentication_error", retryable: false, message: message} =
               AnthropicStreamAdapter.format_error("API error status 401: authentication_error")

      assert message =~ "credentials are invalid"
    end

    test "maps connection failures as retryable" do
      assert %{
               code: "connection_error",
               retryable: true,
               message:
                 "Could not connect to the AI service. Please check your network connection."
             } = AnthropicStreamAdapter.format_error("connection error: :econnrefused")
    end
  end

  describe "Stream.adapter!/1" do
    test "uses the adapter carried by the provider stream config" do
      assert AnthropicStreamAdapter == Stream.adapter!(%{adapter: AnthropicStreamAdapter})
    end

    test "fails fast when a stream config omits the provider adapter" do
      assert_raise ArgumentError, ~r/stream adapter/, fn ->
        Stream.adapter!(%{url: "http://test.local", headers: [], body: %{}})
      end
    end
  end
end
