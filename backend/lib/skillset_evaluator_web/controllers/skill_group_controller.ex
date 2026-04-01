defmodule SkillsetEvaluatorWeb.SkillGroupController do
  use SkillsetEvaluatorWeb, :controller

  alias SkillsetEvaluator.Skills

  def create_skill(conn, %{"id" => skill_group_id, "skill" => params}) do
    attrs = Map.put(params, "skill_group_id", skill_group_id)

    case Skills.create_skill(attrs) do
      {:ok, skill} ->
        conn
        |> put_status(:created)
        |> json(%{data: %{id: skill.id, name: skill.name, priority: skill.priority, position: skill.position, skill_group_id: skill.skill_group_id}})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: format_errors(changeset)})
    end
  end

  defp format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
