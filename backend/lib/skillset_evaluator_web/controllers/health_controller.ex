defmodule SkillsetEvaluatorWeb.HealthController do
  use SkillsetEvaluatorWeb, :controller

  def show(conn, _params) do
    json(conn, %{status: "ok"})
  end
end
