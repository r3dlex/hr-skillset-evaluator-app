defmodule SkillsetEvaluator.OnboardingTest do
  use SkillsetEvaluator.DataCase

  alias SkillsetEvaluator.Accounts
  alias SkillsetEvaluator.Accounts.User

  describe "User.completed_steps/1" do
    test "returns empty list when steps is default" do
      user = user_fixture()
      assert User.completed_steps(user) == []
    end

    test "parses a JSON array of step ids" do
      user = user_fixture()

      {:ok, updated} =
        user
        |> User.onboarding_changeset(%{
          onboarding_completed_steps: ~s(["import_xlsx","view_radar"])
        })
        |> SkillsetEvaluator.Repo.update()

      assert User.completed_steps(updated) == ["import_xlsx", "view_radar"]
    end

    test "returns empty list for malformed JSON" do
      user = %User{onboarding_completed_steps: "not-json"}
      assert User.completed_steps(user) == []
    end

    test "returns empty list when steps is nil" do
      user = %User{onboarding_completed_steps: nil}
      assert User.completed_steps(user) == []
    end
  end

  describe "Accounts.complete_onboarding_step/2" do
    test "appends a new step to completed steps" do
      user = user_fixture()
      assert {:ok, updated} = Accounts.complete_onboarding_step(user, "import_xlsx")
      assert "import_xlsx" in User.completed_steps(updated)
    end

    test "appends multiple distinct steps" do
      user = user_fixture()
      {:ok, user} = Accounts.complete_onboarding_step(user, "import_xlsx")
      {:ok, user} = Accounts.complete_onboarding_step(user, "view_radar")

      steps = User.completed_steps(user)
      assert "import_xlsx" in steps
      assert "view_radar" in steps
      assert length(steps) == 2
    end

    test "deduplicates: completing an already-completed step returns ok without duplicate" do
      user = user_fixture()
      {:ok, user} = Accounts.complete_onboarding_step(user, "import_xlsx")
      {:ok, user} = Accounts.complete_onboarding_step(user, "import_xlsx")

      steps = User.completed_steps(user)
      assert steps == ["import_xlsx"]
    end

    test "returns {:ok, user} unchanged when step already completed" do
      user = user_fixture()
      {:ok, user_with_step} = Accounts.complete_onboarding_step(user, "import_xlsx")

      assert {:ok, ^user_with_step} =
               Accounts.complete_onboarding_step(user_with_step, "import_xlsx")
    end
  end

  describe "Accounts.dismiss_onboarding/1" do
    test "sets onboarding_dismissed to true" do
      user = user_fixture()
      assert user.onboarding_dismissed == false

      assert {:ok, updated} = Accounts.dismiss_onboarding(user)
      assert updated.onboarding_dismissed == true
    end
  end

  describe "Accounts.reset_onboarding/1" do
    test "clears completed steps and sets dismissed to false" do
      user = user_fixture()
      {:ok, user} = Accounts.complete_onboarding_step(user, "import_xlsx")
      {:ok, user} = Accounts.dismiss_onboarding(user)

      assert {:ok, reset} = Accounts.reset_onboarding(user)
      assert User.completed_steps(reset) == []
      assert reset.onboarding_dismissed == false
    end
  end
end
