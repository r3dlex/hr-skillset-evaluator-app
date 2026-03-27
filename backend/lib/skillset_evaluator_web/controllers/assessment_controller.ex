defmodule SkillsetEvaluatorWeb.AssessmentController do
  use SkillsetEvaluatorWeb, :controller

  alias SkillsetEvaluator.Assessments

  @doc """
  List assessments.
  With skillset_id + user_ids: only assessments that have evaluation data.
  Without filters: all assessments.
  """
  def index(conn, params) do
    assessments =
      case {params["skillset_id"], params["user_ids"]} do
        {sid, uids} when is_binary(sid) and is_binary(uids) ->
          skillset_id = String.to_integer(sid)
          user_ids = uids |> String.split(",") |> Enum.map(&String.to_integer/1)
          Assessments.list_assessments_with_data(user_ids, skillset_id)

        _ ->
          Assessments.list_assessments()
      end

    render(conn, :index, assessments: assessments)
  end

  def create(conn, %{"name" => _name} = params) do
    user = conn.assigns.current_user

    attrs = %{
      name: params["name"],
      description: params["description"]
    }

    case Assessments.create_assessment(attrs, user) do
      {:ok, assessment} ->
        conn
        |> put_status(:created)
        |> render(:show, assessment: assessment)

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: format_errors(changeset)})
    end
  end

  def create(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "Missing required parameter: name"})
  end

  defp format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
    |> Enum.map(fn {field, msgs} -> "#{field}: #{Enum.join(msgs, ", ")}" end)
    |> Enum.join("; ")
  end
end
