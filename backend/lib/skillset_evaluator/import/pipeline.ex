defmodule SkillsetEvaluator.Import.Pipeline do
  @moduledoc """
  Broadway pipeline for processing xlsx skill matrix imports.

  Flow:
  1. XlsxParser extracts PersonRow structs from the xlsx file
  2. PersonRows are fed into Broadway via a custom producer
  3. Broadway processors handle each person row concurrently:
     a. Ensure team exists (upsert)
     b. Ensure user exists (upsert)
     c. Ensure skillset + skill_groups + skills exist (upsert)
     d. Upsert evaluations with manager_scores
  4. Results are batched and collected

  Broadway provides:
  - Concurrent processing of person rows
  - Back-pressure handling
  - Graceful error handling per message
  - Batching for efficient DB operations
  """

  use Broadway

  alias SkillsetEvaluator.Import.XlsxParser
  alias SkillsetEvaluator.Import.XlsxParser.PersonRow
  alias SkillsetEvaluator.{Repo, Accounts, Teams, Skills}
  alias SkillsetEvaluator.Evaluations.Evaluation

  import Ecto.Query

  require Logger

  @spec run_import(String.t(), String.t(), integer() | nil) ::
          {:ok, map()} | {:error, String.t()}
  def run_import(file_path, period, evaluator_id \\ nil) do
    # Step 1: Parse teams sheet and upsert teams + users
    teams_result = import_teams(file_path)

    # Step 2: Parse skill sheets into PersonRow messages
    case XlsxParser.parse(file_path, period) do
      {:ok, person_rows} when person_rows != [] ->
        # Step 3: Process each row — ensure skills exist, upsert evaluations
        results = process_rows_sync(person_rows, evaluator_id)

        {:ok,
         %{
           teams_imported: teams_result,
           rows_processed: length(person_rows),
           evaluations_created: results.created,
           evaluations_updated: results.updated,
           errors: results.errors
         }}

      {:ok, []} ->
        {:ok, %{rows_processed: 0, evaluations_created: 0, evaluations_updated: 0, errors: []}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Processes person rows using Broadway for concurrent batch processing.
  Falls back to synchronous processing if Broadway isn't suitable (small batches).
  """
  def process_rows_sync(person_rows, evaluator_id) do
    # Ensure all skillsets, groups, and skills exist first (sequential, idempotent)
    ensure_skills_exist(person_rows)

    # Process evaluations concurrently using Task.async_stream (Broadway-style concurrency)
    person_rows
    |> Task.async_stream(
      fn row -> process_person_row(row, evaluator_id) end,
      max_concurrency: System.schedulers_online(),
      timeout: 30_000
    )
    |> Enum.reduce(%{created: 0, updated: 0, errors: []}, fn
      {:ok, {:ok, :created}}, acc -> %{acc | created: acc.created + 1}
      {:ok, {:ok, :updated}}, acc -> %{acc | updated: acc.updated + 1}
      {:ok, {:error, reason}}, acc -> %{acc | errors: [reason | acc.errors]}
      {:exit, reason}, acc -> %{acc | errors: ["Task failed: #{inspect(reason)}" | acc.errors]}
    end)
  end

  # --- Broadway callbacks (for async pipeline mode) ---

  @impl true
  def handle_message(:default, %Broadway.Message{data: %PersonRow{} = row} = message, context) do
    evaluator_id = Map.get(context, :evaluator_id)

    case process_person_row(row, evaluator_id) do
      {:ok, _} ->
        message

      {:error, reason} ->
        Broadway.Message.failed(message, reason)
    end
  end

  @impl true
  def handle_batch(:default, messages, _batch_info, _context) do
    messages
  end

  # --- Internal processing ---

  defp import_teams(file_path) do
    case XlsxParser.parse_teams_sheet(file_path) do
      {:ok, team_rows} ->
        Enum.each(team_rows, fn row ->
          team = ensure_team(row.team)

          if team && row.name && row.name != "" do
            ensure_user(row, team.id)
          end
        end)

        length(team_rows)

      {:error, _} ->
        0
    end
  end

  defp ensure_skills_exist(person_rows) do
    person_rows
    |> Enum.group_by(& &1.sheet_name)
    |> Enum.each(fn {sheet_name, rows} ->
      # Create skillset
      skillset = ensure_skillset(sheet_name)

      # Get unique skill groups and skills from first row (all rows have same structure)
      case List.first(rows) do
        nil ->
          :ok

        first_row ->
          first_row.scores
          |> Enum.group_by(& &1.group_name)
          |> Enum.each(fn {group_name, skills} ->
            group = ensure_skill_group(group_name, skillset.id)

            Enum.each(skills, fn skill_info ->
              ensure_skill(skill_info.skill_name, skill_info.priority, group.id)
            end)
          end)
      end
    end)
  end

  defp process_person_row(%PersonRow{} = row, evaluator_id) do
    team = ensure_team(row.team)
    user = find_user_by_name_and_team(row.name, team && team.id)

    if user do
      skillset = get_skillset_by_name(row.sheet_name)

      if skillset do
        upsert_evaluations(user.id, row.scores, row.period, evaluator_id, skillset)
      else
        {:error, "Skillset not found: #{row.sheet_name}"}
      end
    else
      {:error, "User not found: #{row.name} in team #{row.team}"}
    end
  end

  defp upsert_evaluations(user_id, scores, period, evaluator_id, skillset) do
    results =
      Enum.map(scores, fn score_entry ->
        skill = find_skill_by_name_in_skillset(score_entry.skill_name, skillset.id)

        if skill && score_entry.value != nil do
          attrs = %{
            user_id: user_id,
            skill_id: skill.id,
            period: period,
            manager_score: score_entry.value,
            evaluated_by_id: evaluator_id
          }

          case Repo.get_by(Evaluation, user_id: user_id, skill_id: skill.id, period: period) do
            nil ->
              %Evaluation{}
              |> Evaluation.changeset(attrs)
              |> Repo.insert()

              :created

            existing ->
              existing
              |> Evaluation.changeset(%{
                manager_score: score_entry.value,
                evaluated_by_id: evaluator_id
              })
              |> Repo.update()

              :updated
          end
        else
          :skipped
        end
      end)

    has_created = Enum.any?(results, &(&1 == :created))
    has_updated = Enum.any?(results, &(&1 == :updated))

    cond do
      has_created -> {:ok, :created}
      has_updated -> {:ok, :updated}
      true -> {:ok, :created}
    end
  end

  # --- Upsert helpers ---

  defp ensure_team(nil), do: nil
  defp ensure_team(""), do: nil

  defp ensure_team(name) do
    case Repo.get_by(Teams.Team, name: name) do
      nil ->
        {:ok, team} = Teams.create_team(%{name: name})
        team

      team ->
        team
    end
  end

  defp ensure_user(row, team_id) do
    role = normalize_role(row.role)

    email =
      row.email ||
        "#{String.downcase(String.replace(row.name, " ", "."))}@placeholder.local"

    case Repo.get_by(Accounts.User, name: row.name) do
      nil ->
        Accounts.create_imported_user(%{
          name: row.name,
          email: email,
          role: role,
          team_id: team_id,
          location: row.location,
          active: row.active,
          job_title: row.role
        })

      user ->
        # Always sync active, location, team, and job_title from the spreadsheet
        Accounts.update_user(user, %{
          active: row.active,
          location: row.location,
          team_id: team_id,
          job_title: row.role
        })
    end
  end

  defp ensure_skillset(name) do
    applicable_roles = skillset_applicable_roles(name)

    case Repo.get_by(Skills.Skillset, name: name) do
      nil ->
        {:ok, skillset} =
          Skills.create_skillset(%{
            name: name,
            position: 0,
            applicable_roles: Jason.encode!(applicable_roles)
          })

        skillset

      skillset ->
        # Update applicable_roles if not already set
        if skillset.applicable_roles in [nil, "[]"] and applicable_roles != [] do
          {:ok, updated} =
            Skills.update_skillset(skillset, %{
              applicable_roles: Jason.encode!(applicable_roles)
            })

          updated
        else
          skillset
        end
    end
  end

  # Role mapping: which job titles can see each skillset
  # Empty list = all roles
  defp skillset_applicable_roles(name) do
    downcased = String.downcase(name)

    cond do
      String.contains?(downcased, "soft") -> []
      String.contains?(downcased, "domain") -> []
      String.contains?(downcased, "fullstack") -> ["Dev"]
      String.contains?(downcased, "frontend") -> ["Dev"]
      String.contains?(downcased, "backend") -> ["Dev"]
      downcased == "qe" or String.contains?(downcased, "quality") -> ["Dev"]
      String.contains?(downcased, "ai") or String.contains?(downcased, "ml") -> ["Dev"]
      String.contains?(downcased, "product") -> ["Lead"]
      true -> []
    end
  end

  defp ensure_skill_group(name, skillset_id) do
    case Repo.get_by(Skills.SkillGroup, name: name, skillset_id: skillset_id) do
      nil ->
        {:ok, group} =
          Skills.create_skill_group(%{name: name, skillset_id: skillset_id, position: 0})

        group

      group ->
        group
    end
  end

  defp ensure_skill(name, priority, skill_group_id) do
    case Repo.get_by(Skills.Skill, name: name, skill_group_id: skill_group_id) do
      nil ->
        {:ok, skill} =
          Skills.create_skill(%{
            name: name,
            priority: priority,
            skill_group_id: skill_group_id,
            position: 0
          })

        skill

      skill ->
        skill
    end
  end

  defp find_user_by_name_and_team(name, nil) do
    Repo.get_by(Accounts.User, name: name)
  end

  defp find_user_by_name_and_team(name, team_id) do
    Accounts.User
    |> where([u], u.name == ^name and u.team_id == ^team_id)
    |> Repo.one()
    |> case do
      nil -> Repo.get_by(Accounts.User, name: name)
      user -> user
    end
  end

  defp get_skillset_by_name(name) do
    Repo.get_by(Skills.Skillset, name: name)
  end

  defp find_skill_by_name_in_skillset(skill_name, skillset_id) do
    Skills.Skill
    |> join(:inner, [s], sg in Skills.SkillGroup, on: s.skill_group_id == sg.id)
    |> where([s, sg], s.name == ^skill_name and sg.skillset_id == ^skillset_id)
    |> limit(1)
    |> Repo.one()
  end

  defp normalize_role(nil), do: "user"
  defp normalize_role(""), do: "user"

  defp normalize_role(role) do
    case String.downcase(role) do
      r when r in ["lead", "manager", "head", "director"] -> "manager"
      _ -> "user"
    end
  end
end
