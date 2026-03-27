defmodule SkillsetEvaluatorWeb.DashboardController do
  use SkillsetEvaluatorWeb, :controller

  alias SkillsetEvaluator.{Repo, Evaluations.Evaluation, Skills, Skills.Skill, Skills.SkillGroup}
  import Ecto.Query

  def stats(conn, params) do
    team_id = params["team_id"] && String.to_integer(params["team_id"])
    period = params["period"]

    # Get all skill IDs
    total_skills =
      Skill
      |> Repo.aggregate(:count, :id)

    # Get members for the team via join table
    members_query =
      if team_id do
        from(u in SkillsetEvaluator.Accounts.User,
          join: ut in SkillsetEvaluator.Teams.UserTeam,
          on: ut.user_id == u.id and ut.team_id == ^team_id,
          where: u.active == true,
          select: u.id)
      else
        from(u in SkillsetEvaluator.Accounts.User, where: u.active == true, select: u.id)
      end

    member_ids = Repo.all(members_query)

    # Evaluations query
    eval_query =
      Evaluation
      |> where([e], e.user_id in ^member_ids)
      |> where([e], not is_nil(e.manager_score))

    eval_query = if period, do: where(eval_query, [e], e.period == ^period), else: eval_query

    skills_rated = Repo.aggregate(eval_query, :count, :id)

    avg_score =
      case Repo.aggregate(eval_query, :avg, :manager_score) do
        nil -> 0
        %Decimal{} = d -> Decimal.to_float(d) |> Float.round(1)
        f when is_float(f) -> Float.round(f, 1)
        i when is_integer(i) -> i / 1.0
      end

    total_possible = total_skills * max(length(member_ids), 1)
    completion = if total_possible > 0, do: round(skills_rated / total_possible * 100), else: 0

    json(conn, %{
      data: %{
        total_skills: total_skills,
        average_score: avg_score,
        skills_rated: skills_rated,
        completion_percentage: min(completion, 100),
        team_size: length(member_ids)
      }
    })
  end
end
