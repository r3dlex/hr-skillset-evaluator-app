defmodule SkillsetEvaluator.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      SkillsetEvaluator.Repo,
      {Phoenix.PubSub, name: SkillsetEvaluator.PubSub},
      SkillsetEvaluatorWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: SkillsetEvaluator.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    SkillsetEvaluatorWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
