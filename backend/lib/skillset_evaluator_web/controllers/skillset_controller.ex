defmodule SkillsetEvaluatorWeb.SkillsetController do
  use SkillsetEvaluatorWeb, :controller

  alias SkillsetEvaluator.Skills

  def index(conn, _params) do
    skillsets = Skills.list_skillsets()
    render(conn, :index, skillsets: skillsets)
  end

  def show(conn, %{"id" => id}) do
    case Skills.get_skillset(id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Skillset not found."})

      skillset ->
        render(conn, :show, skillset: skillset)
    end
  end

  def create(conn, %{"skillset" => skillset_params}) do
    case Skills.create_skillset(skillset_params) do
      {:ok, skillset} ->
        conn
        |> put_status(:created)
        |> render(:show, skillset: skillset)

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
