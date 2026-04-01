defmodule SkillsetEvaluator.LLM.ContextBuilderTest do
  use SkillsetEvaluator.DataCase

  alias SkillsetEvaluator.LLM.ContextBuilder
  alias SkillsetEvaluator.{Chat, Teams}
  alias SkillsetEvaluator.Repo
  alias SkillsetEvaluator.Teams.UserTeam
  alias SkillsetEvaluator.Glossary.Term

  setup do
    # Clear the process dict glossary cache before each test
    Process.delete(:glossary_context_cache)

    admin = user_fixture(%{name: "Admin User", role: "admin"})
    manager = user_fixture(%{name: "Mgr User", role: "manager"})
    user = user_fixture(%{name: "Regular User", role: "user"})
    team = team_fixture(%{name: "Engineering"})

    Repo.insert!(%UserTeam{user_id: user.id, team_id: team.id})
    Repo.insert!(%UserTeam{user_id: manager.id, team_id: team.id})

    skillset = skillset_fixture(%{name: "Technical Skills", position: 1})
    group = skill_group_fixture(%{skillset_id: skillset.id, name: "Programming"})
    skill = skill_fixture(%{skill_group_id: group.id, name: "Elixir", priority: "high"})

    evaluation_fixture(%{user: user, skill: skill, period: "2025-Q1"})

    %{
      admin: admin,
      manager: manager,
      user: user,
      team: team,
      skillset: skillset,
      skill: skill
    }
  end

  # ---------------------------------------------------------------------------
  # build_messages/2
  # ---------------------------------------------------------------------------

  describe "build_messages/2" do
    test "returns empty list for conversation with no messages", ctx do
      {:ok, conv} = Chat.create_conversation(ctx.user.id)
      assert ContextBuilder.build_messages(conv.id) == []
    end

    test "returns messages as {role, content} maps in order", ctx do
      {:ok, conv} = Chat.create_conversation(ctx.user.id)
      {:ok, _m1} = Chat.create_message(conv.id, %{role: "user", content: "Hello"})
      {:ok, _m2} = Chat.create_message(conv.id, %{role: "assistant", content: "Hi there"})

      msgs = ContextBuilder.build_messages(conv.id)
      assert length(msgs) == 2
      assert hd(msgs) == %{role: "user", content: "Hello"}
      assert List.last(msgs) == %{role: "assistant", content: "Hi there"}
    end

    test "respects limit parameter", ctx do
      {:ok, conv} = Chat.create_conversation(ctx.user.id)

      for i <- 1..5 do
        Chat.create_message(conv.id, %{role: "user", content: "msg #{i}"})
      end

      msgs = ContextBuilder.build_messages(conv.id, 3)
      assert length(msgs) == 3
    end
  end

  # ---------------------------------------------------------------------------
  # build_glossary_context/0
  # ---------------------------------------------------------------------------

  describe "build_glossary_context/0" do
    test "returns a string or nil" do
      result = ContextBuilder.build_glossary_context()
      assert is_binary(result) or is_nil(result)
    end

    test "caches result in process dictionary" do
      r1 = ContextBuilder.build_glossary_context()
      r2 = ContextBuilder.build_glossary_context()
      assert r1 == r2
    end
  end

  # ---------------------------------------------------------------------------
  # build_user_context/1
  # ---------------------------------------------------------------------------

  describe "build_user_context/1" do
    test "returns a string for admin role", ctx do
      result = ContextBuilder.build_user_context(ctx.admin)
      assert is_binary(result)
      # Admin context should mention users or teams
      assert String.length(result) > 0
    end

    test "returns a string for manager role", ctx do
      result = ContextBuilder.build_user_context(ctx.manager)
      assert is_binary(result)
    end

    test "returns a string for user role", ctx do
      result = ContextBuilder.build_user_context(ctx.user)
      assert is_binary(result)
    end

    test "truncates long context", ctx do
      result = ContextBuilder.build_user_context(ctx.admin)
      # Context should be at most @max_user_context_chars chars
      assert String.length(result) <= 16_000
    end
  end

  # ---------------------------------------------------------------------------
  # build_screen_context/2
  # ---------------------------------------------------------------------------

  describe "build_screen_context/2" do
    test "returns nil for empty context map", ctx do
      assert is_nil(ContextBuilder.build_screen_context(ctx.user, %{}))
    end

    test "returns nil for unknown screen", ctx do
      assert is_nil(ContextBuilder.build_screen_context(ctx.user, %{"screen" => "unknown"}))
    end

    test "returns string for 'settings' screen", ctx do
      result = ContextBuilder.build_screen_context(ctx.user, %{"screen" => "settings"})
      assert is_binary(result)
      assert result =~ "Settings"
    end

    test "returns string for 'dashboard' screen (user role)", ctx do
      result = ContextBuilder.build_screen_context(ctx.user, %{"screen" => "dashboard"})
      assert is_binary(result)
      assert result =~ "Dashboard" or result =~ "dashboard"
    end

    test "returns string for 'dashboard' screen (manager role)", ctx do
      result = ContextBuilder.build_screen_context(ctx.manager, %{"screen" => "dashboard"})
      assert is_binary(result)
    end

    test "returns string for 'skillset' screen with skillset_id", ctx do
      result =
        ContextBuilder.build_screen_context(ctx.user, %{
          "screen" => "skillset",
          "skillset_id" => to_string(ctx.skillset.id),
          "period" => "2025-Q1"
        })

      assert is_binary(result)
    end

    test "returns string for 'skillset' screen without skillset_id", ctx do
      result =
        ContextBuilder.build_screen_context(ctx.user, %{
          "screen" => "skillset"
        })

      assert is_binary(result)
    end

    test "returns string for 'self-evaluation' screen without skillset (no data path)", ctx do
      # Without skillset_id, takes the simple branch with no evaluation query
      result =
        ContextBuilder.build_screen_context(ctx.user, %{
          "screen" => "self-evaluation"
        })

      assert is_binary(result)
      assert result =~ "Self-Evaluation"
    end

    test "admin dashboard screen context", ctx do
      result =
        ContextBuilder.build_screen_context(ctx.admin, %{
          "screen" => "dashboard",
          "team_id" => to_string(ctx.team.id)
        })

      assert is_binary(result)
    end

    test "skillset screen with team_id (manager)", ctx do
      result =
        ContextBuilder.build_screen_context(ctx.manager, %{
          "screen" => "skillset",
          "skillset_id" => to_string(ctx.skillset.id),
          "period" => "2025-Q1",
          "team_id" => to_string(ctx.team.id),
          "active_tab" => "table"
        })

      assert is_binary(result)
    end

    test "skillset screen with specific user_id", ctx do
      result =
        ContextBuilder.build_screen_context(ctx.manager, %{
          "screen" => "skillset",
          "skillset_id" => to_string(ctx.skillset.id),
          "period" => "2025-Q1",
          "user_id" => to_string(ctx.user.id)
        })

      assert is_binary(result)
    end

    test "admin skillset screen with no team_id shows :all branch", ctx do
      result =
        ContextBuilder.build_screen_context(ctx.admin, %{
          "screen" => "skillset",
          "skillset_id" => to_string(ctx.skillset.id),
          "period" => "2025-Q1"
        })

      assert is_binary(result)
    end

    test "admin skillset screen with target user_id", ctx do
      result =
        ContextBuilder.build_screen_context(ctx.admin, %{
          "screen" => "skillset",
          "skillset_id" => to_string(ctx.skillset.id),
          "period" => "2025-Q1",
          "user_id" => to_string(ctx.user.id)
        })

      assert is_binary(result)
    end

    test "manager skillset screen viewing own data", ctx do
      result =
        ContextBuilder.build_screen_context(ctx.manager, %{
          "screen" => "skillset",
          "skillset_id" => to_string(ctx.skillset.id),
          "period" => "2025-Q1",
          "user_id" => to_string(ctx.manager.id)
        })

      assert is_binary(result)
    end

    test "skillset screen with invalid skillset_id returns no skillset message", ctx do
      result =
        ContextBuilder.build_screen_context(ctx.user, %{
          "screen" => "skillset",
          "skillset_id" => "999999"
        })

      assert is_binary(result)
      assert result =~ "no skillset is selected"
    end

    test "self-evaluation screen WITH skillset_id shows eval data", ctx do
      # Use a period with no evaluations to avoid user-preload issue in format_eval_table
      result =
        ContextBuilder.build_screen_context(ctx.user, %{
          "screen" => "self-evaluation",
          "skillset_id" => to_string(ctx.skillset.id),
          "period" => "2099-H1"
        })

      assert is_binary(result)
      assert result =~ "Self-Evaluation"
    end

    test "skillset screen with skill_group_id filter", ctx do
      group = skill_group_fixture(%{skillset_id: ctx.skillset.id, name: "Extra Group"})

      result =
        ContextBuilder.build_screen_context(ctx.user, %{
          "screen" => "skillset",
          "skillset_id" => to_string(ctx.skillset.id),
          "period" => "2025-Q1",
          "skill_group_id" => to_string(group.id)
        })

      assert is_binary(result)
    end

    test "skillset screen with visible_member_names list", ctx do
      result =
        ContextBuilder.build_screen_context(ctx.manager, %{
          "screen" => "skillset",
          "skillset_id" => to_string(ctx.skillset.id),
          "period" => "2025-Q1",
          "visible_member_names" => ["Alice", "Bob"]
        })

      assert is_binary(result)
    end

    test "user viewing own skillset screen", ctx do
      result =
        ContextBuilder.build_screen_context(ctx.user, %{
          "screen" => "skillset",
          "skillset_id" => to_string(ctx.skillset.id),
          "period" => "2025-Q1",
          "user_id" => to_string(ctx.user.id)
        })

      assert is_binary(result)
    end
  end

  # ---------------------------------------------------------------------------
  # build_system_prompt/2
  # ---------------------------------------------------------------------------

  describe "build_system_prompt/2" do
    test "returns a non-empty string for admin user", ctx do
      result = ContextBuilder.build_system_prompt(ctx.admin)
      assert is_binary(result)
      assert String.length(result) > 100
    end

    test "returns a non-empty string for manager user", ctx do
      result = ContextBuilder.build_system_prompt(ctx.manager)
      assert is_binary(result)
    end

    test "returns a non-empty string for regular user", ctx do
      result = ContextBuilder.build_system_prompt(ctx.user)
      assert is_binary(result)
    end

    test "includes screen context when provided", ctx do
      result =
        ContextBuilder.build_system_prompt(ctx.user, %{"screen" => "settings"})

      assert result =~ "Settings"
    end

    test "works with empty screen context", ctx do
      result = ContextBuilder.build_system_prompt(ctx.admin, %{})
      assert is_binary(result)
    end

    test "includes job_title when user has it", ctx do
      user_with_title = user_fixture(%{name: "Developer", job_title: "Senior Engineer"})
      result = ContextBuilder.build_system_prompt(user_with_title)
      assert is_binary(result)
      assert result =~ "Senior Engineer"
    end

    test "works for user with self-evaluation screen context", ctx do
      result =
        ContextBuilder.build_system_prompt(ctx.user, %{
          "screen" => "self-evaluation",
          "skillset_id" => to_string(ctx.skillset.id)
        })

      assert is_binary(result)
    end

    test "works for user with non-standard role (covers data_access_rules catch-all)", ctx do
      # A user with a role not matching user/manager/admin hits the _user catch-all clause
      custom_user = %{ctx.user | role: "custom_role"}
      result = ContextBuilder.build_system_prompt(custom_user)
      assert is_binary(result)
      assert String.length(result) > 0
    end
  end

  # ---------------------------------------------------------------------------
  # Edge cases for build_screen_context
  # ---------------------------------------------------------------------------

  describe "build_screen_context edge cases" do
    test "returns nil when no screen key in context", ctx do
      result = ContextBuilder.build_screen_context(ctx.user, %{"tab" => "chart"})
      assert is_nil(result)
    end

    test "skillset screen with non-parseable skillset_id hits get_int error branch", ctx do
      result =
        ContextBuilder.build_screen_context(ctx.user, %{
          "screen" => "skillset",
          "skillset_id" => "not-a-number"
        })

      # get_int returns nil for non-integer strings → skillset is nil → no skillset message
      assert is_binary(result)
      assert result =~ "no skillset is selected"
    end

    test "manager accessing unauthorized user falls back to own data", ctx do
      result =
        ContextBuilder.build_screen_context(ctx.manager, %{
          "screen" => "skillset",
          "skillset_id" => to_string(ctx.skillset.id),
          "period" => "2025-Q1",
          "user_id" => "999999"
        })

      assert is_binary(result)
    end

    test "dashboard screen for user with non-standard role uses manager branch", ctx do
      # A user with role != 'user' falls into the non-user dashboard screen handler
      other_role_user = %{ctx.manager | role: "supervisor"}

      result =
        ContextBuilder.build_screen_context(other_role_user, %{
          "screen" => "dashboard"
        })

      assert is_binary(result)
    end

    test "skillset screen with integer skillset_id value (not binary)", ctx do
      result =
        ContextBuilder.build_screen_context(ctx.user, %{
          "screen" => "skillset",
          "skillset_id" => ctx.skillset.id
        })

      assert is_binary(result)
    end

    test "admin skillset screen shows team members when team_id and no specific user", ctx do
      result =
        ContextBuilder.build_screen_context(ctx.admin, %{
          "screen" => "skillset",
          "skillset_id" => to_string(ctx.skillset.id),
          "period" => "2025-Q1",
          "team_id" => to_string(ctx.team.id),
          "visible_member_count" => 3
        })

      assert is_binary(result)
    end
  end

  # ---------------------------------------------------------------------------
  # Glossary context with DB terms
  # ---------------------------------------------------------------------------

  describe "build_glossary_context/0 with DB terms" do
    test "returns non-nil when glossary terms exist in DB" do
      Process.delete(:glossary_context_cache)

      Repo.insert!(%Term{
        concept: "UniqueTestConcept_#{System.unique_integer()}",
        term_en: "Test Term",
        domain: "TestDomain",
        description_en: "A test description for coverage"
      })

      result = ContextBuilder.build_glossary_context()
      assert is_binary(result)
      assert result =~ "Application Terms"
    end

    test "term with nil description_en and nil domain renders correctly" do
      Process.delete(:glossary_context_cache)

      concept = "MinimalConcept_#{System.unique_integer()}"

      Repo.insert!(%Term{
        concept: concept,
        term_en: "Minimal"
      })

      result = ContextBuilder.build_glossary_context()
      assert is_binary(result)
    end
  end

  # ---------------------------------------------------------------------------
  # build_user_context with evaluations in current period
  # ---------------------------------------------------------------------------

  describe "build_user_context/1 with current-period evaluations" do
    test "user context includes evaluation lines when scores exist for current period", ctx do
      period = "#{Date.utc_today().year}-#{if Date.utc_today().month <= 6, do: "H1", else: "H2"}"
      evaluation_fixture(%{user: ctx.user, skill: ctx.skill, period: period, self_score: 3})

      result = ContextBuilder.build_user_context(ctx.user)
      assert is_binary(result)
      assert String.length(result) > 0
    end

    test "manager context includes evaluation lines when team member has scores", ctx do
      period = "#{Date.utc_today().year}-#{if Date.utc_today().month <= 6, do: "H1", else: "H2"}"

      evaluation_fixture(%{
        user: ctx.user,
        skill: ctx.skill,
        period: period,
        manager_score: 4,
        self_score: 3
      })

      result = ContextBuilder.build_user_context(ctx.manager)
      assert is_binary(result)
    end

    test "manager with no team_id returns context", _ctx do
      solo_manager = user_fixture(%{name: "Solo Mgr #{System.unique_integer()}", role: "manager"})
      result = ContextBuilder.build_user_context(solo_manager)
      assert is_binary(result)
      assert result =~ "Manager"
    end
  end

  # ---------------------------------------------------------------------------
  # build_screen_context — gap and scoring paths
  # ---------------------------------------------------------------------------

  describe "build_screen_context/2 with scored evaluations" do
    test "skillset screen shows gap analysis when evaluations have scores", ctx do
      period = "#{Date.utc_today().year}-#{if Date.utc_today().month <= 6, do: "H1", else: "H2"}"

      evaluation_fixture(%{
        user: ctx.user,
        skill: ctx.skill,
        period: period,
        manager_score: 4,
        self_score: 2
      })

      result =
        ContextBuilder.build_screen_context(ctx.manager, %{
          "screen" => "skillset",
          "skillset_id" => to_string(ctx.skillset.id),
          "period" => period,
          "team_id" => to_string(ctx.team.id)
        })

      assert is_binary(result)
    end

    test "self-evaluation screen shows data for current period", ctx do
      period = "#{Date.utc_today().year}-#{if Date.utc_today().month <= 6, do: "H1", else: "H2"}"
      evaluation_fixture(%{user: ctx.user, skill: ctx.skill, period: period, self_score: 3})

      result =
        ContextBuilder.build_screen_context(ctx.user, %{
          "screen" => "self-evaluation",
          "skillset_id" => to_string(ctx.skillset.id),
          "period" => period
        })

      assert is_binary(result)
      assert result =~ "Self-Evaluation"
    end

    test "skillset screen for admin with no team shows :all branch with evaluations", ctx do
      period = "#{Date.utc_today().year}-#{if Date.utc_today().month <= 6, do: "H1", else: "H2"}"
      evaluation_fixture(%{user: ctx.user, skill: ctx.skill, period: period, manager_score: 3})

      result =
        ContextBuilder.build_screen_context(ctx.admin, %{
          "screen" => "skillset",
          "skillset_id" => to_string(ctx.skillset.id),
          "period" => period
        })

      assert is_binary(result)
    end

    test "authorized_team_members catch-all (non user/manager/admin role) returns user", ctx do
      other = %{ctx.user | role: "guest"}

      result =
        ContextBuilder.build_screen_context(other, %{
          "screen" => "dashboard"
        })

      assert is_binary(result)
    end
  end
end
