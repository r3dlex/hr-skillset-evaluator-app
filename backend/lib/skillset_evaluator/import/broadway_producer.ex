defmodule SkillsetEvaluator.Import.BroadwayProducer do
  @moduledoc """
  A custom Broadway producer that emits parsed PersonRow messages from xlsx data.

  Used by the XlsxImportPipeline to feed parsed rows into Broadway's
  processing pipeline for concurrent database upserts.
  """

  use GenStage

  def start_link(opts) do
    GenStage.start_link(__MODULE__, opts)
  end

  @impl true
  def init(_opts) do
    {:producer, %{queue: :queue.new(), demand: 0}}
  end

  @impl true
  def handle_demand(incoming_demand, %{queue: queue, demand: pending_demand} = state) do
    total_demand = incoming_demand + pending_demand
    {messages, remaining_queue, remaining_demand} = take_from_queue(queue, total_demand)
    {:noreply, messages, %{state | queue: remaining_queue, demand: remaining_demand}}
  end

  @impl true
  def handle_cast({:enqueue, person_rows}, %{queue: queue, demand: demand} = state) do
    new_queue =
      Enum.reduce(person_rows, queue, fn row, q ->
        :queue.in(row, q)
      end)

    {messages, remaining_queue, remaining_demand} = take_from_queue(new_queue, demand)
    {:noreply, messages, %{state | queue: remaining_queue, demand: remaining_demand}}
  end

  @impl true
  def handle_cast(:done, state) do
    {:noreply, [], state}
  end

  defp take_from_queue(queue, demand) do
    take_from_queue(queue, demand, [])
  end

  defp take_from_queue(queue, 0, acc) do
    {Enum.reverse(acc), queue, 0}
  end

  defp take_from_queue(queue, demand, acc) do
    case :queue.out(queue) do
      {{:value, item}, new_queue} ->
        message = %Broadway.Message{
          data: item,
          acknowledger: Broadway.NoopAcknowledger.init()
        }

        take_from_queue(new_queue, demand - 1, [message | acc])

      {:empty, empty_queue} ->
        {Enum.reverse(acc), empty_queue, demand}
    end
  end
end
