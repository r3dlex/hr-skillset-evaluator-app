defmodule SkillsetEvaluator.Repo do
  use Ecto.Repo,
    otp_app: :skillset_evaluator,
    adapter: Ecto.Adapters.SQLite3
end
