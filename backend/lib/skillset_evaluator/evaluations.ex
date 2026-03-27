defmodule SkillsetEvaluator.Evaluations do
  @moduledoc """
  The Evaluations context.
  """

  import Ecto.Query
  alias SkillsetEvaluator.Repo
  alias SkillsetEvaluator.Evaluations.Evaluation
  alias SkillsetEvaluator.Skills
  alias SkillsetEvaluator.Skills.{SkillGroup, Skill}
  alias SkillsetEvaluator.Assessments

  def list_evaluations(user_id, skillset_id, period, opts \\ []) do
    skill_group_id = Keyword.get(opts, :skill_group_id)

    skill_ids =
      if skill_group_id do
        skill_ids_for_group(skill_group_id)
      else
        skill_ids_for_skillset(skillset_id)
      end

    Evaluation
    |> where([e], e.user_id == ^user_id and e.period == ^period and e.skill_id in ^skill_ids)
    |> preload(:skill)
    |> Repo.all()
  end

  def get_evaluation(id), do: Repo.get(Evaluation, id)

  def upsert_manager_scores(evaluator, user_id, period, scores_list) do
    {:ok, assessment} = Assessments.find_or_create_assessment(period, evaluator)

    Repo.transaction(fn ->
      Enum.map(scores_list, fn %{skill_id: skill_id, score: score} = entry ->
        notes = Map.get(entry, :notes)

        case Repo.get_by(Evaluation, user_id: user_id, skill_id: skill_id, period: period) do
          %Evaluation{} = eval ->
            eval
            |> Evaluation.changeset(%{
              manager_score: score,
              evaluated_by_id: evaluator.id,
              notes: notes,
              assessment_id: assessment.id
            })
            |> Repo.update!()

          nil ->
            %Evaluation{}
            |> Evaluation.changeset(%{
              user_id: user_id,
              skill_id: skill_id,
              period: period,
              manager_score: score,
              evaluated_by_id: evaluator.id,
              notes: notes,
              assessment_id: assessment.id
            })
            |> Repo.insert!()
        end
      end)
    end)
  end

  def upsert_self_scores(user_id, period, scores_list) do
    {:ok, assessment} = Assessments.find_or_create_assessment(period)

    Repo.transaction(fn ->
      Enum.map(scores_list, fn %{skill_id: skill_id, score: score} ->
        case Repo.get_by(Evaluation, user_id: user_id, skill_id: skill_id, period: period) do
          %Evaluation{} = eval ->
            eval
            |> Evaluation.changeset(%{self_score: score, assessment_id: assessment.id})
            |> Repo.update!()

          nil ->
            %Evaluation{}
            |> Evaluation.changeset(%{
              user_id: user_id,
              skill_id: skill_id,
              period: period,
              self_score: score,
              assessment_id: assessment.id
            })
            |> Repo.insert!()
        end
      end)
    end)
  end

  def get_radar_data(user_ids, skillset_id, period) when is_list(user_ids) do
    skill_ids = skill_ids_for_skillset(skillset_id)

    evaluations =
      Evaluation
      |> where([e], e.user_id in ^user_ids and e.period == ^period and e.skill_id in ^skill_ids)
      |> preload(:skill)
      |> Repo.all()

    skillset = Skills.get_skillset(skillset_id)

    labels =
      skillset.skill_groups
      |> Enum.flat_map(fn sg ->
        Enum.map(sg.skills, fn skill -> skill.name end)
      end)

    datasets =
      Enum.map(user_ids, fn uid ->
        user_evals = Enum.filter(evaluations, &(&1.user_id == uid))

        manager_data =
          Enum.map(labels, fn label ->
            eval = Enum.find(user_evals, &(&1.skill.name == label))
            if eval, do: eval.manager_score, else: nil
          end)

        self_data =
          Enum.map(labels, fn label ->
            eval = Enum.find(user_evals, &(&1.skill.name == label))
            if eval, do: eval.self_score, else: nil
          end)

        %{user_id: uid, manager_scores: manager_data, self_scores: self_data}
      end)

    %{labels: labels, datasets: datasets}
  end

  def get_radar_data_for_group(user_ids, skill_group_id, period) when is_list(user_ids) do
    skills =
      Skill
      |> where([s], s.skill_group_id == ^skill_group_id)
      |> order_by([s], s.position)
      |> Repo.all()

    skill_ids = Enum.map(skills, & &1.id)
    labels = Enum.map(skills, & &1.name)

    evaluations =
      Evaluation
      |> where([e], e.user_id in ^user_ids and e.period == ^period and e.skill_id in ^skill_ids)
      |> preload(:skill)
      |> Repo.all()

    datasets =
      Enum.map(user_ids, fn uid ->
        user_evals = Enum.filter(evaluations, &(&1.user_id == uid))

        manager_data =
          Enum.map(labels, fn label ->
            eval = Enum.find(user_evals, &(&1.skill.name == label))
            if eval, do: eval.manager_score, else: nil
          end)

        self_data =
          Enum.map(labels, fn label ->
            eval = Enum.find(user_evals, &(&1.skill.name == label))
            if eval, do: eval.self_score, else: nil
          end)

        %{user_id: uid, manager_scores: manager_data, self_scores: self_data}
      end)

    %{labels: labels, datasets: datasets}
  end

  def get_gap_analysis(user_id, skillset_id, period, opts \\ []) do
    skill_group_id = Keyword.get(opts, :skill_group_id)

    skill_ids =
      if skill_group_id do
        skill_ids_for_group(skill_group_id)
      else
        skill_ids_for_skillset(skillset_id)
      end

    team_id = Keyword.get(opts, :team_id)
    location = Keyword.get(opts, :location)

    # Get user's evaluations
    evaluations =
      Evaluation
      |> where([e], e.user_id == ^user_id and e.period == ^period and e.skill_id in ^skill_ids)
      |> preload(skill: [:skill_group])
      |> Repo.all()

    # Get the user to know their job_title
    user = Repo.get(SkillsetEvaluator.Accounts.User, user_id)

    # Compute team averages per skill
    team_avgs = compute_team_averages(skill_ids, period, team_id, location)

    # Compute role averages per skill (same job_title across org)
    role_avgs =
      if user && user.job_title do
        compute_role_averages(skill_ids, period, user.job_title, location)
      else
        %{}
      end

    # Build skills map for items without evaluations
    all_skills = skills_for_skillset(skillset_id)

    # Start with evaluated skills
    evaluated_skill_ids = MapSet.new(Enum.map(evaluations, & &1.skill_id))

    eval_items =
      Enum.map(evaluations, fn eval ->
        gap =
          case {eval.manager_score, eval.self_score} do
            {nil, _} -> nil
            {_, nil} -> nil
            {ms, ss} -> ms - ss
          end

        %{
          skill_id: eval.skill_id,
          skill_name: eval.skill.name,
          priority: eval.skill.priority,
          manager_score: eval.manager_score,
          self_score: eval.self_score,
          gap: gap,
          team_avg: Map.get(team_avgs, eval.skill_id),
          role_avg: Map.get(role_avgs, eval.skill_id)
        }
      end)

    # Add skills that have no personal evaluation but have team/role data
    missing_items =
      all_skills
      |> Enum.reject(fn s -> MapSet.member?(evaluated_skill_ids, s.id) end)
      |> Enum.filter(fn s ->
        Map.has_key?(team_avgs, s.id) or Map.has_key?(role_avgs, s.id)
      end)
      |> Enum.map(fn s ->
        %{
          skill_id: s.id,
          skill_name: s.name,
          priority: s.priority,
          manager_score: nil,
          self_score: nil,
          gap: nil,
          team_avg: Map.get(team_avgs, s.id),
          role_avg: Map.get(role_avgs, s.id)
        }
      end)

    eval_items ++ missing_items
  end

  defp compute_team_averages(skill_ids, period, team_id, location) do
    query =
      Evaluation
      |> join(:inner, [e], u in SkillsetEvaluator.Accounts.User, on: e.user_id == u.id)
      |> where([e, u], e.period == ^period and e.skill_id in ^skill_ids)
      |> where([e, u], not is_nil(e.manager_score))

    query =
      if team_id do
        query
        |> join(:inner, [e, u], ut in SkillsetEvaluator.Teams.UserTeam,
          on: ut.user_id == u.id and ut.team_id == ^team_id
        )
      else
        query
      end

    query =
      if location && location != "",
        do: where(query, [e, u], u.location == ^location),
        else: query

    query
    |> group_by([e, u], e.skill_id)
    |> select([e, u], {e.skill_id, avg(e.manager_score)})
    |> Repo.all()
    |> Map.new(fn {skill_id, avg} ->
      {skill_id, to_rounded_float(avg)}
    end)
  end

  defp to_rounded_float(nil), do: nil
  defp to_rounded_float(%Decimal{} = d), do: Decimal.to_float(d) |> Float.round(1)
  defp to_rounded_float(f) when is_float(f), do: Float.round(f, 1)
  defp to_rounded_float(i) when is_integer(i), do: i / 1.0

  defp compute_role_averages(skill_ids, period, job_title, location) do
    query =
      Evaluation
      |> join(:inner, [e], u in SkillsetEvaluator.Accounts.User, on: e.user_id == u.id)
      |> where([e, u], e.period == ^period and e.skill_id in ^skill_ids)
      |> where([e, u], not is_nil(e.manager_score))
      |> where([e, u], u.job_title == ^job_title)

    query =
      if location && location != "",
        do: where(query, [e, u], u.location == ^location),
        else: query

    query
    |> group_by([e, u], e.skill_id)
    |> select([e, u], {e.skill_id, avg(e.manager_score)})
    |> Repo.all()
    |> Map.new(fn {skill_id, avg} ->
      {skill_id, to_rounded_float(avg)}
    end)
  end

  defp skills_for_skillset(skillset_id) do
    Skill
    |> join(:inner, [s], sg in SkillGroup, on: s.skill_group_id == sg.id)
    |> where([s, sg], sg.skillset_id == ^skillset_id)
    |> Repo.all()
  end

  def list_periods(user_ids, skillset_id) when is_list(user_ids) and length(user_ids) > 0 do
    skill_ids = skill_ids_for_skillset(skillset_id)

    Evaluation
    |> where([e], e.user_id in ^user_ids and e.skill_id in ^skill_ids)
    |> select([e], e.period)
    |> distinct(true)
    |> order_by([e], desc: e.period)
    |> Repo.all()
  end

  def list_periods(_user_ids, _skillset_id), do: []

  defp skill_ids_for_skillset(skillset_id) do
    Skill
    |> join(:inner, [s], sg in SkillGroup, on: s.skill_group_id == sg.id)
    |> where([s, sg], sg.skillset_id == ^skillset_id)
    |> select([s], s.id)
    |> Repo.all()
  end

  defp skill_ids_for_group(skill_group_id) do
    Skill
    |> where([s], s.skill_group_id == ^skill_group_id)
    |> select([s], s.id)
    |> Repo.all()
  end
end
