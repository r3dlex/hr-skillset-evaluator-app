defmodule SkillsetEvaluator.LLM.RateLimiter do
  @moduledoc """
  Per-user rate limiter using ETS for LLM chat requests.

  Limits:
  - user: 30 requests/hour
  - manager: 60 requests/hour
  - admin: 120 requests/hour
  """

  use GenServer

  @table_name :chat_rate_limits
  @cleanup_interval :timer.minutes(10)

  # Requests per hour by role
  @limits %{
    "user" => 30,
    "manager" => 60,
    "admin" => 120
  }

  ## Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Checks if the user is within rate limits.
  Returns :ok or {:error, :rate_limited, retry_after_seconds}.
  """
  def check_rate(user_id, role) do
    ensure_table_exists()

    limit = Map.get(@limits, role, 30)
    now = System.system_time(:second)
    window_start = now - 3600

    key = {:rate, user_id}

    case :ets.lookup(@table_name, key) do
      [{^key, requests}] ->
        # Filter out old requests
        recent = Enum.filter(requests, fn ts -> ts > window_start end)

        if length(recent) >= limit do
          oldest = Enum.min(recent)
          retry_after = oldest + 3600 - now
          {:error, :rate_limited, max(retry_after, 1)}
        else
          :ets.insert(@table_name, {key, [now | recent]})
          :ok
        end

      [] ->
        :ets.insert(@table_name, {key, [now]})
        :ok
    end
  end

  @doc """
  Returns the current request count for a user within the hour window.
  """
  def get_count(user_id) do
    ensure_table_exists()

    key = {:rate, user_id}
    now = System.system_time(:second)
    window_start = now - 3600

    case :ets.lookup(@table_name, key) do
      [{^key, requests}] ->
        Enum.count(requests, fn ts -> ts > window_start end)

      [] ->
        0
    end
  end

  ## Server Callbacks

  @impl true
  def init(_opts) do
    create_table()
    schedule_cleanup()
    {:ok, %{}}
  end

  @impl true
  def handle_info(:cleanup, state) do
    cleanup_old_entries()
    schedule_cleanup()
    {:noreply, state}
  end

  ## Private

  defp create_table do
    :ets.new(@table_name, [:named_table, :set, :public, read_concurrency: true])
  rescue
    ArgumentError -> :ok
  end

  defp ensure_table_exists do
    case :ets.whereis(@table_name) do
      :undefined -> create_table()
      _ -> :ok
    end
  end

  defp schedule_cleanup do
    Process.send_after(self(), :cleanup, @cleanup_interval)
  end

  defp cleanup_old_entries do
    now = System.system_time(:second)
    window_start = now - 3600

    :ets.foldl(
      fn {key, requests}, _acc ->
        recent = Enum.filter(requests, fn ts -> ts > window_start end)

        if Enum.empty?(recent) do
          :ets.delete(@table_name, key)
        else
          :ets.insert(@table_name, {key, recent})
        end

        :ok
      end,
      :ok,
      @table_name
    )
  rescue
    _ -> :ok
  end
end
