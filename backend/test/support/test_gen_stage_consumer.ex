defmodule SkillsetEvaluator.Test.GenStageConsumer do
  @moduledoc false
  use GenStage

  def start_link(producer_pid) do
    GenStage.start_link(__MODULE__, producer_pid)
  end

  def init(producer_pid) do
    {:consumer, :ok, subscribe_to: [{producer_pid, max_demand: 5, min_demand: 0}]}
  end

  def handle_events(_events, _from, state) do
    {:noreply, [], state}
  end
end
