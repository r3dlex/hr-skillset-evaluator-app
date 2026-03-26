defmodule SkillsetEvaluatorWeb.RadarJSON do
  def show(%{radar: radar}) do
    %{data: radar}
  end
end
