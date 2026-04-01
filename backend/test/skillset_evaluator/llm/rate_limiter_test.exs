defmodule SkillsetEvaluator.LLM.RateLimiterTest do
  use ExUnit.Case, async: false

  alias SkillsetEvaluator.LLM.RateLimiter

  describe "check_rate/2" do
    test "allows first request for a user" do
      user_id = System.unique_integer()
      assert :ok = RateLimiter.check_rate(user_id, "user")
    end

    test "allows requests within user limit (30/hour)" do
      user_id = System.unique_integer()

      for _ <- 1..10 do
        assert :ok = RateLimiter.check_rate(user_id, "user")
      end
    end

    test "allows requests within manager limit (60/hour)" do
      user_id = System.unique_integer()

      for _ <- 1..20 do
        assert :ok = RateLimiter.check_rate(user_id, "manager")
      end
    end

    test "allows requests within admin limit (120/hour)" do
      user_id = System.unique_integer()

      for _ <- 1..30 do
        assert :ok = RateLimiter.check_rate(user_id, "admin")
      end
    end

    test "rate limits when user exceeds limit" do
      user_id = System.unique_integer()

      for _ <- 1..30 do
        RateLimiter.check_rate(user_id, "user")
      end

      assert {:error, :rate_limited, retry_after} = RateLimiter.check_rate(user_id, "user")
      assert retry_after >= 1
    end

    test "rate limits when manager exceeds limit" do
      user_id = System.unique_integer()

      for _ <- 1..60 do
        RateLimiter.check_rate(user_id, "manager")
      end

      assert {:error, :rate_limited, _} = RateLimiter.check_rate(user_id, "manager")
    end

    test "uses default limit (30) for unknown role" do
      user_id = System.unique_integer()

      for _ <- 1..30 do
        RateLimiter.check_rate(user_id, "unknown_role")
      end

      assert {:error, :rate_limited, _} = RateLimiter.check_rate(user_id, "unknown_role")
    end

    test "tracks requests independently per user" do
      u1 = System.unique_integer()
      u2 = System.unique_integer()

      for _ <- 1..30 do
        RateLimiter.check_rate(u1, "user")
      end

      assert {:error, :rate_limited, _} = RateLimiter.check_rate(u1, "user")
      assert :ok = RateLimiter.check_rate(u2, "user")
    end
  end

  describe "get_count/1" do
    test "returns 0 for a user with no requests" do
      user_id = System.unique_integer()
      assert RateLimiter.get_count(user_id) == 0
    end

    test "returns the correct count after requests" do
      user_id = System.unique_integer()

      for _ <- 1..5 do
        RateLimiter.check_rate(user_id, "user")
      end

      assert RateLimiter.get_count(user_id) == 5
    end
  end

  describe "GenServer lifecycle" do
    setup do
      pid =
        case RateLimiter.start_link([]) do
          {:ok, p} -> p
          {:error, {:already_started, p}} -> p
        end

      on_exit(fn ->
        if Process.alive?(pid), do: Process.exit(pid, :normal)
      end)

      %{rl_pid: pid}
    end

    test "start_link/1 starts a named process", %{rl_pid: pid} do
      assert is_pid(pid)
      assert Process.whereis(RateLimiter) == pid
    end

    test "handle_info :cleanup runs without error", %{rl_pid: pid} do
      send(pid, :cleanup)
      :timer.sleep(20)
      assert Process.alive?(pid)
    end

    test "cleanup removes stale entries (older than 1 hour)", %{rl_pid: pid} do
      stale_key = {:rate, :stale_cleanup_test}
      old_ts = System.system_time(:second) - 7200

      RateLimiter.check_rate(:init_table_user, "user")
      :ets.insert(:chat_rate_limits, {stale_key, [old_ts]})
      assert :ets.lookup(:chat_rate_limits, stale_key) != []

      send(pid, :cleanup)
      :timer.sleep(50)
      assert :ets.lookup(:chat_rate_limits, stale_key) == []
    end

    test "cleanup retains recent entries", %{rl_pid: pid} do
      recent_key = {:rate, :recent_cleanup_test}
      recent_ts = System.system_time(:second)

      RateLimiter.check_rate(:init_table_user2, "user")
      :ets.insert(:chat_rate_limits, {recent_key, [recent_ts]})

      send(pid, :cleanup)
      :timer.sleep(50)
      assert :ets.lookup(:chat_rate_limits, recent_key) != []
    end
  end
end
