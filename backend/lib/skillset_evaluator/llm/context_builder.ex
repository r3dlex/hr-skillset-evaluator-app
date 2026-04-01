defmodule SkillsetEvaluator.LLM.ContextBuilder do
  @moduledoc """
  Assembles the multi-layer system prompt and conversation messages for LLM calls.

  Progressive disclosure layers:
  Layer 0: Agent identity + guidelines (from llm/AGENTS.md)
  Layer 1: Domain glossary (from data/glossary_aec_construction.md + DB terms)
  Layer 2: User context — role-scoped data (admin/manager/user)
  Layer 3: Available skills reference (file paths for on-demand knowledge)
  """

  import Ecto.Query

  alias SkillsetEvaluator.Repo
  alias SkillsetEvaluator.Glossary.Term
  alias SkillsetEvaluator.Chat.Message
  alias SkillsetEvaluator.Accounts.User
  alias SkillsetEvaluator.Evaluations
  alias SkillsetEvaluator.Skills

  require Logger

  @max_user_context_chars 16_000

  # Paths to mounted knowledge files (read-only mounts in Docker)
  @agent_instructions_path "/app/llm/AGENTS.md"
  @glossary_file_path "/app/data/glossary_aec_construction.md"
  @skills_dir "/app/llm/skills"
  @spec_dir "/app/spec"

  @max_screen_context_chars 4_000

  @doc """
  Builds the full system prompt for the given user.
  Uses progressive disclosure: loads agent instructions + glossary summary + user context.
  Optionally includes screen context for the user's current view.
  """
  def build_system_prompt(%User{} = user, screen_context \\ %{}) do
    [
      load_agent_instructions(user),
      build_glossary_context(),
      build_user_context(user),
      build_screen_context(user, screen_context),
      build_data_access_rules(user),
      build_available_knowledge()
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.join("\n\n---\n\n")
  end

  @doc """
  Builds the message list from conversation history.
  """
  def build_messages(conversation_id, limit \\ 20) do
    Message
    |> where([m], m.conversation_id == ^conversation_id)
    |> where([m], m.role in ["user", "assistant"])
    |> order_by([m], desc: m.inserted_at)
    |> limit(^limit)
    |> Repo.all()
    |> Enum.reverse()
    |> Enum.map(fn msg ->
      %{role: msg.role, content: msg.content}
    end)
  end

  @doc """
  Builds the glossary context string from glossary_terms table.
  Uses process dictionary as a simple cache within the request lifecycle.
  """
  def build_glossary_context do
    case Process.get(:glossary_context_cache) do
      nil ->
        context = do_build_glossary_context()
        Process.put(:glossary_context_cache, context)
        context

      cached ->
        cached
    end
  end

  @doc """
  Builds role-scoped user context data.
  """
  def build_user_context(%User{} = user) do
    context =
      case user.role do
        "admin" -> build_admin_context()
        "manager" -> build_manager_context(user)
        _ -> build_user_only_context(user)
      end

    truncate_context(context, @max_user_context_chars)
  end

  # -- Screen Context (Layer 4) --

  @doc """
  Builds context for the user's current active screen.
  The backend re-validates all data access server-side — the frontend only sends
  screen identifiers and filter state, never raw data.
  """
  def build_screen_context(%User{} = user, %{"screen" => screen} = ctx) do
    context =
      case screen do
        "dashboard" ->
          build_dashboard_screen(user, ctx)

        "skillset" ->
          build_skillset_screen(user, ctx)

        "self-evaluation" ->
          build_self_eval_screen(user, ctx)

        "settings" ->
          "The user is viewing the Settings page. No evaluation data is relevant here."

        _ ->
          nil
      end

    if context do
      truncate_context("## Active Screen Context\n\n#{context}", @max_screen_context_chars)
    else
      nil
    end
  end

  def build_screen_context(_user, _ctx), do: nil

  defp build_dashboard_screen(%User{role: "user"} = user, _ctx) do
    skillsets = Skills.list_skillsets()
    stats = build_user_dashboard_stats(user, skillsets)

    """
    The user is viewing their **Dashboard** with personal overview statistics.

    #{stats}

    The user may ask about their overall performance, completion rate, or scores.
    Only discuss this user's own data.
    """
  end

  defp build_dashboard_screen(%User{} = user, ctx) do
    team_id = get_int(ctx, "team_id") || user.team_id
    team_members = authorized_team_members(user, team_id)
    skillsets = Skills.list_skillsets()
    stats = build_manager_dashboard_stats(team_members, skillsets)

    """
    The user is viewing the **Manager Dashboard**.
    Team: #{length(team_members)} members#{if team_id, do: " (team ID: #{team_id})", else: ""}

    #{stats}

    The user may ask about team statistics, completion rates, or average scores.
    Only discuss data for the team members listed above.
    """
  end

  defp build_skillset_screen(%User{} = user, ctx) do
    skillset_id = get_int(ctx, "skillset_id")
    skill_group_id = get_int(ctx, "skill_group_id")
    period = ctx["period"] || current_period()
    active_tab = ctx["active_tab"] || "chart"
    target_user_id = get_int(ctx, "user_id")
    team_id = get_int(ctx, "team_id")
    visible_member_count = get_int(ctx, "visible_member_count")
    visible_member_names = Map.get(ctx, "visible_member_names")

    skillset = if skillset_id, do: Skills.get_skillset(skillset_id), else: nil

    # Determine which user's data to show, respecting role boundaries
    viewable_user_ids = authorized_user_ids(user, target_user_id)

    # For team overview (no specific user), get actual team members
    viewable_user_ids =
      if is_nil(target_user_id) and user.role in ["admin", "manager"] do
        actual_team_id = team_id || user.team_id

        if actual_team_id do
          SkillsetEvaluator.Accounts.list_users_by_team(actual_team_id) |> Enum.map(& &1.id)
        else
          viewable_user_ids
        end
      else
        viewable_user_ids
      end

    if is_nil(skillset) do
      "The user is viewing a Skillset page, but no skillset is selected."
    else
      evals = fetch_scoped_evaluations(viewable_user_ids, skillset_id, period, skill_group_id)
      gap = fetch_scoped_gap_analysis(viewable_user_ids, skillset_id, period, skill_group_id)

      viewing_label =
        case {user.role, target_user_id} do
          {_, nil} when user.role in ["admin", "manager"] ->
            member_desc =
              if visible_member_names && is_list(visible_member_names) do
                " (#{Enum.join(visible_member_names, ", ")})"
              else
                count = visible_member_count || length(List.wrap(viewable_user_ids))
                " (#{count} team members)"
              end

            "team overview — All members#{member_desc}"

          {_, uid} when uid == user.id ->
            "their own evaluations"

          {role, uid} when role in ["admin", "manager"] ->
            target = Repo.get(User, uid)
            if target, do: "evaluations for #{target.name || target.email}", else: "selected user"

          _ ->
            "their own evaluations"
        end

      group_label =
        if skill_group_id do
          group = Repo.get(SkillsetEvaluator.Skills.SkillGroup, skill_group_id)
          if group, do: "Skill group: **#{group.name}**", else: ""
        else
          "All skill groups"
        end

      # Summarize how many evaluations have actual scores
      scored_count = Enum.count(evals, fn e -> e.manager_score != nil or e.self_score != nil end)
      total_count = length(evals)

      """
      The user is viewing: **#{skillset.name}** — #{viewing_label}
      Active tab: **#{active_tab}** (chart = radar chart, table = data table, gap = gap analysis)
      Period: #{period}
      #{group_label}
      Data: #{scored_count} scored evaluations out of #{total_count} total

      #{if active_tab == "chart" do
        "The radar chart is currently displayed. Each colored line represents a different team member's manager assessment scores. The chart axes are the skills in the selected group."
      else
        ""
      end}

      ### Evaluation Data Currently on Screen
      #{format_eval_table(evals)}

      #{if gap != [] do
        "### Gap Analysis\n#{format_gap_table(gap)}"
      else
        ""
      end}

      The user may ask you to explain charts, interpret scores, identify strengths/weaknesses, or suggest development areas.
      """
    end
  end

  defp build_self_eval_screen(%User{} = user, ctx) do
    skillset_id = get_int(ctx, "skillset_id")
    period = ctx["period"] || current_period()

    if skillset_id do
      evals =
        Evaluations.list_evaluations(user.id, skillset_id, period)
        |> Repo.preload([:user, :skill])

      skillset = Skills.get_skillset(skillset_id)

      """
      The user is on the **Self-Evaluation** page for #{if skillset, do: skillset.name, else: "a skillset"}.
      Period: #{period}

      ### Current Self-Evaluation Scores
      #{format_eval_table(evals)}

      The user may ask for guidance on how to rate themselves or what each proficiency level means.
      Only discuss this user's own scores.
      """
    else
      "The user is on the Self-Evaluation page."
    end
  end

  # -- Data Access Rules (GDPR/Compliance Harness) --

  defp build_data_access_rules(%User{role: "user"} = user) do
    """
    ## Data Access Rules (MANDATORY — GDPR/Compliance)

    Current user: #{user.name || user.email} (role: user)

    **CRITICAL RESTRICTIONS:**
    - You MUST NOT reveal, discuss, or reference data about ANY other user.
    - You can ONLY discuss this user's own evaluations, scores, and profile.
    - If asked about other employees, team members, or aggregated data, respond:
      "I can only help with your own evaluation data. Please ask your manager for team-level information."
    - Never enumerate users, reveal names, emails, or scores of other people.
    - Never provide team-level statistics, averages, or comparisons.
    - If the context above contains no data, say so — do not fabricate scores.
    """
  end

  defp build_data_access_rules(%User{role: "manager"} = user) do
    """
    ## Data Access Rules (MANDATORY — GDPR/Compliance)

    Current user: #{user.name || user.email} (role: manager)

    **RESTRICTIONS:**
    - You may discuss data for team members listed in the context above.
    - You MUST NOT reveal data about users outside your team.
    - If asked about users not in your team, respond:
      "I can only provide information about your direct team members."
    - Never fabricate data. If information is not in the context, say so.
    - Be careful with individual performance data — present it constructively.
    """
  end

  defp build_data_access_rules(%User{role: "admin"} = user) do
    """
    ## Data Access Rules (MANDATORY — GDPR/Compliance)

    Current user: #{user.name || user.email} (role: admin)

    **RESTRICTIONS:**
    - You have access to all system data as an administrator.
    - Present data factually and constructively.
    - Never fabricate data. If information is not in the context, say so.
    - Be mindful that HR data is sensitive — avoid unnecessarily listing personal details.
    """
  end

  defp build_data_access_rules(_user), do: nil

  # -- Authorization Helpers --

  defp authorized_user_ids(%User{role: "admin"}, nil), do: :all
  defp authorized_user_ids(%User{role: "admin"}, target_id), do: [target_id]

  defp authorized_user_ids(%User{role: "manager"} = user, target_id) do
    team_ids = authorized_team_member_ids(user)

    cond do
      is_nil(target_id) -> team_ids
      target_id in team_ids -> [target_id]
      target_id == user.id -> [user.id]
      # Fall back to own data if unauthorized
      true -> [user.id]
    end
  end

  defp authorized_user_ids(%User{} = user, _target_id), do: [user.id]

  defp authorized_team_members(%User{role: "admin"}, team_id) when not is_nil(team_id) do
    SkillsetEvaluator.Accounts.list_users_by_team(team_id)
  end

  defp authorized_team_members(%User{role: "admin"}, _team_id) do
    Repo.all(from(u in User, where: u.active == true))
  end

  defp authorized_team_members(%User{role: "manager"} = user, _team_id) do
    if user.team_id do
      SkillsetEvaluator.Accounts.list_users_by_team(user.team_id)
    else
      [user]
    end
  end

  defp authorized_team_members(%User{} = user, _team_id), do: [user]

  defp authorized_team_member_ids(%User{} = user) do
    if user.team_id do
      SkillsetEvaluator.Accounts.list_users_by_team(user.team_id)
      |> Enum.map(& &1.id)
    else
      [user.id]
    end
  end

  # -- Data Fetching Helpers --

  defp fetch_scoped_evaluations(:all, skillset_id, period, skill_group_id) do
    opts = if skill_group_id, do: [skill_group_id: skill_group_id], else: []
    # For admin "all" view, show aggregated — fetch a sample set
    users = Repo.all(from(u in User, where: u.active == true, limit: 10, select: u.id))

    users
    |> Enum.flat_map(fn uid -> Evaluations.list_evaluations(uid, skillset_id, period, opts) end)
    |> Repo.preload(:user)
  end

  defp fetch_scoped_evaluations(user_ids, skillset_id, period, skill_group_id)
       when is_list(user_ids) do
    opts = if skill_group_id, do: [skill_group_id: skill_group_id], else: []

    user_ids
    |> Enum.flat_map(fn uid -> Evaluations.list_evaluations(uid, skillset_id, period, opts) end)
    |> Repo.preload(:user)
  end

  defp fetch_scoped_gap_analysis(:all, skillset_id, period, skill_group_id) do
    opts = if skill_group_id, do: [skill_group_id: skill_group_id], else: []
    users = Repo.all(from(u in User, where: u.active == true, limit: 10, select: u.id))

    Enum.flat_map(users, fn uid ->
      case Evaluations.get_gap_analysis(uid, skillset_id, period, opts) do
        {:ok, gaps} -> gaps
        _ -> []
      end
    end)
  end

  defp fetch_scoped_gap_analysis(user_ids, skillset_id, period, skill_group_id)
       when is_list(user_ids) do
    opts = if skill_group_id, do: [skill_group_id: skill_group_id], else: []

    Enum.flat_map(user_ids, fn uid ->
      case Evaluations.get_gap_analysis(uid, skillset_id, period, opts) do
        {:ok, gaps} -> gaps
        _ -> []
      end
    end)
  end

  # -- Formatting Helpers --

  defp format_eval_table([]), do: "No evaluation data available for this view."

  defp format_eval_table(evals) do
    lines =
      Enum.map(evals, fn e ->
        skill_name = if e.skill, do: e.skill.name, else: "Skill ##{e.skill_id}"
        user_name = if e.user, do: e.user.name || e.user.email, else: "User ##{e.user_id}"

        "| #{user_name} | #{skill_name} | #{e.manager_score || "N/A"} | #{e.self_score || "N/A"} |"
      end)
      # Limit rows to control prompt size
      |> Enum.take(50)

    """
    | User | Skill | Manager Score | Self Score |
    |------|-------|:---:|:---:|
    #{Enum.join(lines, "\n")}
    """
  end

  defp format_gap_table([]), do: ""

  defp format_gap_table(gaps) do
    lines =
      Enum.map(gaps, fn g ->
        "| #{g.skill_name || "?"} | #{g.manager_score || "N/A"} | #{g.self_score || "N/A"} | #{g.gap || "N/A"} |"
      end)
      |> Enum.take(30)

    """
    | Skill | Manager | Self | Gap |
    |-------|:---:|:---:|:---:|
    #{Enum.join(lines, "\n")}
    """
  end

  defp build_user_dashboard_stats(user, skillsets) do
    lines =
      Enum.flat_map(skillsets, fn ss ->
        evals = Evaluations.list_evaluations(user.id, ss.id, current_period())

        if Enum.empty?(evals) do
          []
        else
          avg = evals |> Enum.map(& &1.self_score) |> Enum.reject(&is_nil/1) |> average()
          rated = Enum.count(evals, fn e -> e.self_score != nil end)
          ["- #{ss.name}: #{rated} skills rated, self avg #{format_avg(avg)}"]
        end
      end)

    if Enum.empty?(lines), do: "No evaluation data yet.", else: Enum.join(lines, "\n")
  end

  defp build_manager_dashboard_stats(members, skillsets) do
    total_skills = length(skillsets) * length(members)

    rated =
      Enum.sum(
        Enum.map(members, fn m ->
          Enum.sum(
            Enum.map(skillsets, fn ss ->
              Evaluations.list_evaluations(m.id, ss.id, current_period())
              |> Enum.count(fn e -> e.manager_score != nil or e.self_score != nil end)
            end)
          )
        end)
      )

    "Total skills tracked: #{total_skills}, Rated: #{rated}"
  end

  defp get_int(map, key) do
    case Map.get(map, key) do
      nil ->
        nil

      val when is_integer(val) ->
        val

      val when is_binary(val) ->
        case Integer.parse(val) do
          {n, _} -> n
          :error -> nil
        end

      _ ->
        nil
    end
  end

  # -- Private --

  defp load_agent_instructions(%User{} = user) do
    base_instructions =
      case File.read(@agent_instructions_path) do
        {:ok, content} ->
          content

        {:error, _} ->
          Logger.warning(
            "Agent instructions not found at #{@agent_instructions_path}, using fallback"
          )

          fallback_identity()
      end

    """
    #{base_instructions}

    ---

    ## Current Session

    Current user: #{user.name || user.email}
    Role: #{user.role}
    #{if user.job_title, do: "Job title: #{user.job_title}", else: ""}
    Locale: en
    Period: #{current_period()}
    """
  end

  defp fallback_identity do
    """
    ## Identity

    You are **SkillBot**, the AI assistant for SkillForge.
    You help users understand skill evaluations, provide professional development guidance,
    and answer questions about skillsets, competency frameworks, and evaluation processes.

    - Scores range from 0 (no competency) to 5 (expert level).
    - Distinguish between manager assessment and self-assessment.
    - Do not fabricate data. If you don't know something, say so honestly.
    """
  end

  defp build_available_knowledge do
    skills = list_available_skills()
    specs = list_available_specs()

    if Enum.empty?(skills) and Enum.empty?(specs) do
      nil
    else
      skill_lines = Enum.map(skills, fn {name, path} -> "- **#{name}**: `#{path}`" end)
      spec_lines = Enum.map(specs, fn {name, path} -> "- **#{name}**: `#{path}`" end)

      """
      ## Available Knowledge (Progressive Disclosure)

      You have access to detailed knowledge files. Reference them when relevant to the conversation.

      ### Skills (How-to guides)
      #{Enum.join(skill_lines, "\n")}

      ### Specifications (System documentation)
      #{Enum.join(spec_lines, "\n")}

      When a user's question requires deeper knowledge, consult the relevant file above.
      """
    end
  end

  defp list_available_skills do
    case File.ls(@skills_dir) do
      {:ok, files} ->
        files
        |> Enum.filter(&String.ends_with?(&1, ".md"))
        |> Enum.sort()
        |> Enum.map(fn file ->
          name =
            file
            |> String.replace_suffix(".md", "")
            |> String.replace("_", " ")
            |> String.capitalize()

          {name, Path.join(@skills_dir, file)}
        end)

      {:error, _} ->
        []
    end
  end

  defp list_available_specs do
    case File.ls(@spec_dir) do
      {:ok, files} ->
        files
        |> Enum.filter(&String.ends_with?(&1, ".md"))
        |> Enum.sort()
        |> Enum.map(fn file ->
          name = file |> String.replace_suffix(".md", "") |> String.replace("_", " ")
          {name, Path.join(@spec_dir, file)}
        end)

      {:error, _} ->
        []
    end
  end

  defp do_build_glossary_context do
    # Layer 1a: Load glossary from database (if available)
    db_terms = load_db_glossary_terms()

    # Layer 1b: Load AEC glossary summary from mounted file
    file_glossary = load_file_glossary()

    parts = [db_terms, file_glossary] |> Enum.reject(&is_nil/1)

    if Enum.empty?(parts) do
      nil
    else
      "## Glossary\n\n" <> Enum.join(parts, "\n\n")
    end
  end

  defp load_db_glossary_terms do
    terms = Repo.all(from(t in Term, order_by: [t.domain, t.concept]))

    if Enum.empty?(terms) do
      nil
    else
      term_lines =
        Enum.map(terms, fn t ->
          desc = if t.description_en, do: " — #{t.description_en}", else: ""
          domain = if t.domain, do: " [#{t.domain}]", else: ""
          "- #{t.concept}#{domain}: #{t.term_en || t.concept}#{desc}"
        end)

      """
      ### Application Terms

      #{Enum.join(term_lines, "\n")}
      """
    end
  end

  defp load_file_glossary do
    case File.read(@glossary_file_path) do
      {:ok, content} ->
        # Include a condensed summary (first ~2000 chars) to keep prompt size manageable.
        # The full glossary file path is provided for deeper reference.
        summary = String.slice(content, 0, 2000)

        truncated =
          if byte_size(content) > 2000,
            do: "\n\n[Full AEC glossary available at #{@glossary_file_path}]",
            else: ""

        """
        ### AEC Construction Glossary (Summary)

        #{summary}#{truncated}
        """

      {:error, _} ->
        nil
    end
  end

  defp build_admin_context do
    users =
      Repo.all(from(u in User, where: u.active == true, select: {u.id, u.name, u.email, u.role}))

    skillsets = Skills.list_skillsets()

    user_lines =
      Enum.map(users, fn {id, name, email, role} ->
        "- #{name || email} (ID: #{id}, role: #{role})"
      end)

    skillset_lines =
      Enum.map(skillsets, fn ss ->
        "- #{ss.name} (ID: #{ss.id})"
      end)

    """
    ## User Context (Admin View)

    You have access to all system data as an administrator.

    ### Users (#{length(users)} active)
    #{Enum.join(user_lines, "\n")}

    ### Skillsets
    #{Enum.join(skillset_lines, "\n")}
    """
  end

  defp build_manager_context(%User{} = user) do
    team_members =
      if user.team_id do
        SkillsetEvaluator.Accounts.list_users_by_team(user.team_id)
      else
        []
      end

    member_lines =
      Enum.map(team_members, fn m ->
        "- #{m.name || m.email} (ID: #{m.id})"
      end)

    skillsets = Skills.list_skillsets()

    eval_summary =
      Enum.flat_map(team_members, fn member ->
        Enum.flat_map(skillsets, fn ss ->
          evals = Evaluations.list_evaluations(member.id, ss.id, current_period())

          if Enum.empty?(evals) do
            []
          else
            avg_manager =
              evals
              |> Enum.map(& &1.manager_score)
              |> Enum.reject(&is_nil/1)
              |> average()

            avg_self =
              evals
              |> Enum.map(& &1.self_score)
              |> Enum.reject(&is_nil/1)
              |> average()

            [
              "- #{member.name || member.email} / #{ss.name}: manager avg #{format_avg(avg_manager)}, self avg #{format_avg(avg_self)}"
            ]
          end
        end)
      end)

    """
    ## User Context (Manager View)

    You manage a team with #{length(team_members)} members.

    ### Team Members
    #{Enum.join(member_lines, "\n")}

    ### Evaluation Summary (#{current_period()})
    #{if Enum.empty?(eval_summary), do: "No evaluations yet.", else: Enum.join(eval_summary, "\n")}
    """
  end

  defp build_user_only_context(%User{} = user) do
    skillsets = Skills.list_skillsets()

    eval_lines =
      Enum.flat_map(skillsets, fn ss ->
        evals = Evaluations.list_evaluations(user.id, ss.id, current_period())

        if Enum.empty?(evals) do
          []
        else
          Enum.map(evals, fn e ->
            skill_name = if e.skill, do: e.skill.name, else: "Skill ##{e.skill_id}"

            "- #{skill_name} (#{ss.name}): manager=#{e.manager_score || "N/A"}, self=#{e.self_score || "N/A"}"
          end)
        end
      end)

    """
    ## User Context (Your Evaluations)

    ### Your Evaluation Scores (#{current_period()})
    #{if Enum.empty?(eval_lines), do: "No evaluations yet.", else: Enum.join(eval_lines, "\n")}
    """
  end

  defp current_period do
    today = Date.utc_today()
    half = if today.month <= 6, do: "H1", else: "H2"
    "#{today.year}-#{half}"
  end

  defp average([]), do: nil

  defp average(scores) do
    sum = Enum.sum(scores)
    Float.round(sum / length(scores), 1)
  end

  defp format_avg(nil), do: "N/A"
  defp format_avg(val), do: "#{val}"

  defp truncate_context(text, max_chars) when byte_size(text) <= max_chars, do: text

  defp truncate_context(text, max_chars) do
    String.slice(text, 0, max_chars) <> "\n\n[Context truncated due to size limits]"
  end
end
