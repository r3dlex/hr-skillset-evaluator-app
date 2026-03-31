defmodule SkillsetEvaluator.Export.XlsxWriter do
  @moduledoc """
  Generates xlsx workbooks matching the import format so round-trip is idempotent.
  """

  alias SkillsetEvaluator.{Repo, Skills, Evaluations, Accounts, Teams}
  alias Elixlsx.{Workbook, Sheet}

  import Ecto.Query

  @doc """
  Generate an xlsx binary for a single skillset + period + user set.
  Returns {:ok, binary} or {:error, reason}.
  """
  def generate(skillset_id, period, user_ids) do
    skillset = Skills.get_skillset!(skillset_id)
    groups = skillset.skill_groups || []

    skills =
      Enum.flat_map(groups, fn g -> Enum.map(g.skills, &Map.put(&1, :group_name, g.name)) end)

    # Load users with team info
    users = load_users_with_teams(user_ids)

    # Load evaluations keyed by {user_id, skill_id}
    eval_map = load_eval_map(user_ids, skillset_id, period)

    # Build the skill sheet
    skill_sheet = build_skill_sheet(skillset.name, groups, skills, users, eval_map)

    # Build the Teams sheet
    teams_sheet = build_teams_sheet()

    workbook = %Workbook{sheets: [skill_sheet, teams_sheet]}

    case Elixlsx.write_to_memory(workbook, "export.xlsx") do
      {:ok, {_filename, binary}} -> {:ok, binary}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Generate a full workbook with all skillsets.
  """
  def generate_all(period, user_ids) do
    skillsets = Skills.list_skillsets()

    sheets =
      Enum.map(skillsets, fn skillset ->
        skillset = Skills.get_skillset!(skillset.id)
        groups = skillset.skill_groups || []

        skills =
          Enum.flat_map(groups, fn g ->
            Enum.map(g.skills, &Map.put(&1, :group_name, g.name))
          end)

        eval_map = load_eval_map(user_ids, skillset.id, period)
        users = load_users_with_teams(user_ids)

        build_skill_sheet(skillset.name, groups, skills, users, eval_map)
      end)

    teams_sheet = build_teams_sheet()
    workbook = %Workbook{sheets: sheets ++ [teams_sheet]}

    case Elixlsx.write_to_memory(workbook, "export.xlsx") do
      {:ok, {_filename, binary}} -> {:ok, binary}
      {:error, reason} -> {:error, reason}
    end
  end

  # --- Private ---

  defp build_skill_sheet(sheet_name, _groups, skills, users, eval_map) do
    # Row 1: Group names repeated across their column spans
    row1 =
      [nil, nil, nil, "Skillset"] ++
        Enum.map(skills, fn s -> s.group_name end)

    # Row 2: Priority per skill
    row2 =
      [nil, nil, nil, "Priority/Module"] ++
        Enum.map(skills, fn s -> format_priority(s.priority) end)

    # Row 3: Headers
    row3 =
      ["Team", "Location", "Role", "Name/Skill"] ++
        Enum.map(skills, fn s -> s.name end)

    # Data rows
    data_rows =
      Enum.map(users, fn user ->
        team_name = user[:team_name] || ""
        location = user.location || ""
        role = user.job_title || ""
        name = user.name || ""

        scores =
          Enum.map(skills, fn skill ->
            case Map.get(eval_map, {user.id, skill.id}) do
              nil -> nil
              score -> score
            end
          end)

        [team_name, location, role, name] ++ scores
      end)

    rows = [row1, row2, row3] ++ data_rows

    %Sheet{name: sheet_name, rows: rows}
  end

  defp build_teams_sheet do
    teams = Teams.list_teams_with_member_count()

    rows =
      [["Team", "Members"]] ++
        Enum.map(teams, fn team ->
          members =
            Teams.list_team_members(team.id)
            |> Enum.map(fn u -> u.email end)
            |> Enum.join(", ")

          [team.name, members]
        end)

    %Sheet{name: "Teams", rows: rows}
  end

  defp load_users_with_teams(user_ids) do
    Accounts.User
    |> where([u], u.id in ^user_ids)
    |> Repo.all()
    |> Enum.map(fn user ->
      # Get first team name
      team_name =
        case Repo.all(
               from ut in "user_teams",
                 join: t in SkillsetEvaluator.Teams.Team,
                 on: t.id == ut.team_id,
                 where: ut.user_id == ^user.id,
                 select: t.name,
                 limit: 1
             ) do
          [name] -> name
          _ -> ""
        end

      Map.put(user, :team_name, team_name)
    end)
  end

  defp load_eval_map(user_ids, skillset_id, period) do
    skill_ids =
      Skills.Skill
      |> join(:inner, [s], sg in Skills.SkillGroup, on: s.skill_group_id == sg.id)
      |> where([s, sg], sg.skillset_id == ^skillset_id)
      |> select([s], s.id)
      |> Repo.all()

    Evaluations.Evaluation
    |> where([e], e.user_id in ^user_ids and e.skill_id in ^skill_ids and e.period == ^period)
    |> select([e], {e.user_id, e.skill_id, e.manager_score})
    |> Repo.all()
    |> Map.new(fn {uid, sid, score} -> {{uid, sid}, score} end)
  end

  defp format_priority("critical"), do: "Critical"
  defp format_priority("high"), do: "High"
  defp format_priority("medium"), do: "Medium"
  defp format_priority("low"), do: "Low"
  defp format_priority(other), do: other || "Medium"
end
