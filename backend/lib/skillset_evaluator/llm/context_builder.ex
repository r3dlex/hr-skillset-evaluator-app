defmodule SkillsetEvaluator.LLM.ContextBuilder do
  @moduledoc """
  Assembles the 4-layer system prompt and conversation messages for LLM calls.

  Layer 1: Identity — static role description
  Layer 2: Glossary — domain terms from glossary_terms table
  Layer 3: User Context — role-scoped data (admin/manager/user)
  Layer 4: Conversation history (via messages)
  """

  import Ecto.Query

  alias SkillsetEvaluator.Repo
  alias SkillsetEvaluator.Glossary.Term
  alias SkillsetEvaluator.Chat.Message
  alias SkillsetEvaluator.Accounts.User
  alias SkillsetEvaluator.Evaluations
  alias SkillsetEvaluator.Skills

  @max_user_context_chars 16_000

  @doc """
  Builds the full system prompt for the given user.
  """
  def build_system_prompt(%User{} = user) do
    [
      build_identity(user),
      build_glossary_context(),
      build_user_context(user)
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

  defp build_identity(%User{} = user) do
    """
    ## Identity

    You are an AI assistant for the HR Skillset Evaluator application. Your name is SkillBot.
    You help users understand their skill evaluations, provide guidance on professional development,
    and answer questions about skillsets, competency frameworks, and evaluation processes.

    Current user: #{user.name || user.email}
    Role: #{user.role}
    Locale: en

    Guidelines:
    - Be professional, concise, and helpful.
    - Use the glossary terms correctly when discussing skills and competencies.
    - Scores range from 0 (no competency) to 5 (expert level).
    - When discussing evaluations, distinguish between self-assessment and manager assessment.
    - Do not fabricate data; only reference information provided in the context below.
    - If you don't know something, say so honestly.
    """
  end

  defp do_build_glossary_context do
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
      ## Glossary

      The following domain terms are used in this application:

      #{Enum.join(term_lines, "\n")}
      """
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
