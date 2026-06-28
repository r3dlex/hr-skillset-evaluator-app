defmodule SkillsetEvaluator.LLM.Stream do
  @moduledoc """
  Provider-neutral streaming runner for LLM SSE responses.
  """

  require Logger

  @type token_usage :: map()
  @type error_data :: %{code: String.t(), message: String.t(), retryable: boolean()}
  @type config :: %{
          required(:url) => String.t(),
          required(:headers) => list(),
          required(:body) => map(),
          required(:adapter) => module()
        }

  @callback parse_chunk(data :: binary(), token_usage()) :: {binary(), token_usage()}
  @callback format_error(reason :: term()) :: error_data()
  @callback extract_error(status :: integer(), body :: term()) :: binary()

  @spec adapter!(map()) :: module()
  def adapter!(%{adapter: adapter}) when is_atom(adapter), do: adapter

  def adapter!(_stream_config) do
    raise ArgumentError, "provider stream config must include a stream adapter"
  end

  @spec run(Plug.Conn.t(), map()) :: {:ok, binary(), token_usage()} | {:error, term()}
  def run(conn, %{url: url, headers: headers, body: body} = stream_config) do
    adapter = adapter!(stream_config)
    parent = self()

    task =
      Task.async(fn ->
        result =
          req_post(url,
            json: body,
            headers: headers,
            receive_timeout: 120_000,
            into: fn {:data, data}, {req, resp} ->
              send(parent, {:sse_chunk, data})
              {:cont, {req, resp}}
            end
          )

        notify_result(parent, adapter, result)
        result
      end)

    result = collect_chunks(conn, adapter, "", %{}, task)
    Process.demonitor(task.ref, [:flush])
    result
  rescue
    exception ->
      Logger.error("SSE stream error: #{inspect(exception)}")
      {:error, "Streaming failed"}
  end

  @spec format_error(map(), term()) :: error_data()
  def format_error(stream_config, reason) do
    stream_config
    |> adapter!()
    |> format_adapter_error(reason)
  end

  defp notify_result(parent, adapter, result) do
    case result do
      {:ok, %{status: status, body: body}} when status != 200 ->
        send(parent, {:stream_error, adapter.extract_error(status, body)})

      {:error, %{reason: reason}} ->
        send(parent, {:stream_error, "connection error: #{inspect(reason)}"})

      {:error, reason} ->
        send(parent, {:stream_error, inspect(reason)})

      _ ->
        :ok
    end
  end

  defp collect_chunks(conn, adapter, accumulated, token_usage, task) do
    receive do
      {:sse_chunk, data} ->
        {new_text, new_usage} = adapter.parse_chunk(data, token_usage)

        if new_text != "" do
          delta_data = Jason.encode!(%{content: new_text})
          Plug.Conn.chunk(conn, "event: delta\ndata: #{delta_data}\n\n")
        end

        collect_chunks(conn, adapter, accumulated <> new_text, new_usage, task)

      {:stream_error, reason} ->
        Logger.error("LLM stream error: #{reason}")
        {:error, reason}

      {ref, _result} when is_reference(ref) ->
        if accumulated == "" do
          {:error, "No response from LLM provider"}
        else
          {:ok, accumulated, token_usage}
        end

      {:DOWN, _ref, :process, _pid, _reason} ->
        {:ok, accumulated, token_usage}
    after
      120_000 ->
        {:error, "Stream timeout"}
    end
  end

  defp req_post(url, opts) do
    case Application.get_env(:skillset_evaluator, :llm_stream_test_http) ||
           Application.get_env(:skillset_evaluator, :controller_test_http) do
      nil -> Req.post(url, opts)
      mock -> mock.(url, opts)
    end
  end

  defp format_adapter_error(adapter, reason), do: adapter.format_error(reason)
end
