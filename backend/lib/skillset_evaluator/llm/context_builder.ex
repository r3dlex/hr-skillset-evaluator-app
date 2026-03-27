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

  @doc """
  Builds the full system prompt for the given user.
  Uses progressive disclosure: loads agent instructions + glossary summary + user context.
  """
  def build_system_prompt(%User{} = user) do
    [
      load_agent_instructions(user),
      build_glossary_context(),
      build_user_context(user),
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

    You are **SkillBot**, the AI assistant for the HR Skillset Evaluator application.
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
