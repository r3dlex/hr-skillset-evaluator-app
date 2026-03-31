defmodule SkillsetEvaluator.Accounts.UserTest do
  use SkillsetEvaluator.DataCase

  alias SkillsetEvaluator.Accounts.User

  describe "changeset/2" do
    test "valid changeset with required fields" do
      changeset = User.changeset(%User{}, %{email: "test@example.com", role: "user"})
      assert changeset.valid?
    end

    test "invalid without email" do
      changeset = User.changeset(%User{}, %{})
      assert %{email: _} = errors_on(changeset)
    end

    test "invalid email format" do
      changeset = User.changeset(%User{}, %{email: "notanemail"})
      assert %{email: _} = errors_on(changeset)
    end

    test "invalid role" do
      changeset = User.changeset(%User{}, %{email: "a@b.com", role: "superadmin"})
      assert %{role: _} = errors_on(changeset)
    end

    test "valid roles accepted" do
      for role <- ["user", "manager", "admin"] do
        changeset = User.changeset(%User{}, %{email: "a@b.com", role: role})
        assert changeset.valid?, "Expected #{role} to be valid"
      end
    end
  end

  describe "registration_changeset/2" do
    test "valid with email + password" do
      changeset =
        User.registration_changeset(%User{}, %{
          email: "reg@example.com",
          password: "password123",
          name: "Reg User"
        })

      assert changeset.valid?
    end

    test "invalid without password" do
      changeset = User.registration_changeset(%User{}, %{email: "reg@example.com"})
      assert %{password: _} = errors_on(changeset)
    end

    test "invalid with short password" do
      changeset =
        User.registration_changeset(%User{}, %{email: "reg@example.com", password: "short"})

      assert %{password: _} = errors_on(changeset)
    end
  end

  describe "onboarding_changeset/2" do
    test "casts onboarding fields" do
      user = user_fixture()
      changeset = User.onboarding_changeset(user, %{onboarding_dismissed: true})
      assert get_change(changeset, :onboarding_dismissed) == true
    end
  end

  describe "parsed_scope/1" do
    test "returns nil when manager_scope is nil" do
      user = %User{manager_scope: nil}
      assert is_nil(User.parsed_scope(user))
    end

    test "returns nil when manager_scope is empty string" do
      user = %User{manager_scope: ""}
      assert is_nil(User.parsed_scope(user))
    end

    test "parses valid JSON manager_scope" do
      scope = Jason.encode!(%{"roles" => ["engineer"], "locations" => ["Berlin"]})
      user = %User{manager_scope: scope}
      result = User.parsed_scope(user)
      assert result["roles"] == ["engineer"]
      assert result["locations"] == ["Berlin"]
    end

    test "returns nil for invalid JSON" do
      user = %User{manager_scope: "not-valid-json"}
      assert is_nil(User.parsed_scope(user))
    end

    test "returns nil for non-struct" do
      assert is_nil(User.parsed_scope("not a struct"))
    end
  end

  describe "has_full_access?/1" do
    test "admin has full access" do
      user = %User{role: "admin", manager_scope: "something"}
      assert User.has_full_access?(user)
    end

    test "user with nil manager_scope has full access" do
      user = %User{role: "manager", manager_scope: nil}
      assert User.has_full_access?(user)
    end

    test "user with empty manager_scope has full access" do
      user = %User{role: "manager", manager_scope: ""}
      assert User.has_full_access?(user)
    end

    test "user with manager_scope does not have full access" do
      user = %User{role: "manager", manager_scope: Jason.encode!(%{"team_only" => true})}
      refute User.has_full_access?(user)
    end
  end

  describe "completed_steps/1" do
    test "returns empty list when no steps" do
      user = %User{onboarding_completed_steps: "[]"}
      assert User.completed_steps(user) == []
    end

    test "returns steps list" do
      user = %User{onboarding_completed_steps: Jason.encode!(["step1", "step2"])}
      assert User.completed_steps(user) == ["step1", "step2"]
    end

    test "returns empty list for nil" do
      user = %User{onboarding_completed_steps: nil}
      assert User.completed_steps(user) == []
    end

    test "returns empty list for invalid JSON" do
      user = %User{onboarding_completed_steps: "invalid"}
      assert User.completed_steps(user) == []
    end
  end

  describe "add_completed_step/2" do
    test "adds a step to completed steps" do
      user = user_fixture()
      changeset = User.add_completed_step(user, "import_xlsx")
      assert get_change(changeset, :onboarding_completed_steps) =~ "import_xlsx"
    end

    test "deduplicates steps" do
      user = user_fixture()
      {:ok, user} = SkillsetEvaluator.Accounts.complete_onboarding_step(user, "step1")
      # After completing step1 once, add_completed_step should still return just ["step1"]
      changeset = User.add_completed_step(user, "step1")
      # The changeset should either have the same value or be unchanged
      raw =
        Ecto.Changeset.get_change(changeset, :onboarding_completed_steps) ||
          user.onboarding_completed_steps ||
          "[]"

      new_steps = Jason.decode!(raw)
      assert length(new_steps) == 1
      assert "step1" in new_steps
    end
  end

  describe "valid_password?/2" do
    test "returns true for correct password" do
      user = user_fixture()
      # Re-fetch with hashed_password
      db_user = SkillsetEvaluator.Repo.get(User, user.id)
      assert User.valid_password?(db_user, valid_user_password())
    end

    test "returns false for wrong password" do
      user = user_fixture()
      db_user = SkillsetEvaluator.Repo.get(User, user.id)
      refute User.valid_password?(db_user, "wrong_password")
    end

    test "returns false when hashed_password is nil" do
      user = %User{hashed_password: nil}
      refute User.valid_password?(user, "anypassword")
    end

    test "returns false for empty password" do
      user = user_fixture()
      db_user = SkillsetEvaluator.Repo.get(User, user.id)
      refute User.valid_password?(db_user, "")
    end
  end
end
