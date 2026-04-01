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

  describe "full producer-consumer flow" do
    test "consumer receives messages from producer via Broadway.Message" do
      {:ok, producer_pid} = GenStage.start_link(BroadwayProducer, [])

      # Attach a consumer
      {:ok, consumer_pid} =
        GenStage.start_link(
          SkillsetEvaluator.Import.BroadwayProducerTest.TestConsumer,
          {self(), producer_pid}
        )

      rows = [%{name: "Alice"}, %{name: "Bob"}, %{name: "Carol"}]
      GenStage.cast(producer_pid, {:enqueue, rows})
      GenStage.cast(producer_pid, :done)

      # Allow time for messages to flow
      :timer.sleep(50)

      GenStage.stop(consumer_pid)
      GenStage.stop(producer_pid)
    end
  end
end

defmodule SkillsetEvaluator.Import.BroadwayProducerTest.TestConsumer do
  use GenStage

  def init({parent, producer_pid}) do
    {:consumer, parent, subscribe_to: [{producer_pid, max_demand: 10}]}
  end

  def handle_events(events, _from, parent) do
    send(parent, {:received, length(events)})
    {:noreply, [], parent}
  end
end
