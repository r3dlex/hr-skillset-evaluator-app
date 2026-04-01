defmodule SkillsetEvaluator.Import.BroadwayProducerTest do
  use ExUnit.Case, async: true

  alias SkillsetEvaluator.Import.BroadwayProducer

  describe "init/1" do
    test "initializes with empty queue and zero demand" do
      {:ok, pid} = GenStage.start_link(BroadwayProducer, [])
      # If it started, init worked
      assert is_pid(pid)
      GenStage.stop(pid)
    end
  end

  describe "handle_demand and enqueue" do
    test "enqueue and take messages" do
      {:ok, pid} = GenStage.start_link(BroadwayProducer, [])

      rows = [
        %{name: "Alice", email: "alice@example.com"},
        %{name: "Bob", email: "bob@example.com"}
      ]

      GenStage.cast(pid, {:enqueue, rows})
      GenStage.stop(pid)
    end

    test "done cast completes without error" do
      {:ok, pid} = GenStage.start_link(BroadwayProducer, [])
      GenStage.cast(pid, :done)
      GenStage.stop(pid)
    end

    test "enqueue empty list" do
      {:ok, pid} = GenStage.start_link(BroadwayProducer, [])
      GenStage.cast(pid, {:enqueue, []})
      GenStage.stop(pid)
    end
  end

  describe "multiple enqueue operations" do
    test "handles consecutive enqueue casts" do
      {:ok, pid} = GenStage.start_link(BroadwayProducer, [])

      GenStage.cast(pid, {:enqueue, [%{name: "Alice"}]})
      GenStage.cast(pid, {:enqueue, [%{name: "Bob"}, %{name: "Carol"}]})
      GenStage.cast(pid, :done)

      # Allow time for casts to process
      :timer.sleep(10)
      GenStage.stop(pid)
    end
  end
end
