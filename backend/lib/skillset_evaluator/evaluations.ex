defmodule SkillsetEvaluator.Evaluations do
  @moduledoc """
  The Evaluations context.
  """

  import Ecto.Query
  alias SkillsetEvaluator.Repo
  alias SkillsetEvaluator.Evaluations.Evaluation
  alias SkillsetEvaluator.Skills
  alias SkillsetEvaluator.Skills.{SkillGroup, Skill}

  def list_evaluations(user_id, skillset_id, period) do
    skill_ids = skill_ids_for_skillset(skillset_id)

    Evaluation
    |> where([e], e.user_id == ^user_id and e.period == ^period and e.skill_id in ^skill_ids)
    |> preload(:skill)
    |> Repo.all()
  end

  def get_evaluation(id), do: Repo.get(Evaluation, id)

  def upsert_manager_scores(evaluator, user_id, period, scores_list) do
    Repo.transaction(fn ->
      Enum.map(scores_list, fn %{skill_id: skill_id, score: score} = entry ->
        notes = Map.get(entry, :notes)

        case Repo.get_by(Evaluation, user_id: user_id, skill_id: skill_id, period: period) do
          %Evaluation{} = eval ->
            eval
            |> Evaluation.changeset(%{
              manager_score: score,
              evaluated_by_id: evaluator.id,
              notes: notes
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
              notes: notes
            })
            |> Repo.insert!()
        end
      end)
    end)
  end

  def upsert_self_scores(user_id, period, scores_list) do
    Repo.transaction(fn ->
      Enum.map(scores_list, fn %{skill_id: skill_id, score: score} ->
        case Repo.get_by(Evaluation, user_id: user_id, skill_id: skill_id, period: period) do
          %Evaluation{} = eval ->
            eval
            |> Evaluation.changeset(%{self_score: score})
            |> Repo.update!()

          nil ->
            %Evaluation{}
            |> Evaluation.changeset(%{
              user_id: user_id,
              skill_id: skill_id,
              period: period,
              self_score: score
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

  def get_gap_analysis(user_id, skillset_id, period) do
    skill_ids = skill_ids_for_skillset(skillset_id)

    evaluations =
      Evaluation
      |> where([e], e.user_id == ^user_id and e.period == ^period and e.skill_id in ^skill_ids)
      |> preload(:skill)
      |> Repo.all()

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
        manager_score: eval.manager_score,
        self_score: eval.self_score,
        gap: gap
      }
    end)
  end

  defp skill_ids_for_skillset(skillset_id) do
    Skill
    |> join(:inner, [s], sg in SkillGroup, on: s.skill_group_id == sg.id)
    |> where([s, sg], sg.skillset_id == ^skillset_id)
    |> select([s], s.id)
    |> Repo.all()
  end
end
