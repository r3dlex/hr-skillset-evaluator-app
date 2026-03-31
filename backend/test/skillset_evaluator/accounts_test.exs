defmodule SkillsetEvaluator.AccountsTest do
  use SkillsetEvaluator.DataCase

  alias SkillsetEvaluator.Accounts

  describe "create_user/1" do
    test "creates a user with valid attributes" do
      attrs = %{
        email: unique_user_email(),
        password: valid_user_password(),
        name: "Alice",
        role: "user"
      }

      assert {:ok, user} = Accounts.create_user(attrs)
      assert user.email == attrs.email
      assert user.name == "Alice"
      assert user.role == "user"
      assert user.active == true
      assert is_binary(user.hashed_password)
      assert is_nil(user.password)
    end

    test "returns error changeset with missing email" do
      assert {:error, changeset} = Accounts.create_user(%{password: "validpass1"})
      assert %{email: ["can't be blank"]} = errors_on(changeset)
    end

    test "returns error changeset with invalid email format" do
      attrs = %{email: "nope", password: valid_user_password(), name: "Bob"}
      assert {:error, changeset} = Accounts.create_user(attrs)
      assert %{email: ["must have the @ sign and no spaces"]} = errors_on(changeset)
    end

    test "returns error changeset with short password" do
      attrs = %{email: unique_user_email(), password: "short", name: "Bob"}
      assert {:error, changeset} = Accounts.create_user(attrs)
      assert %{password: [msg]} = errors_on(changeset)
      assert msg =~ "should be at least 8 character"
    end

    test "returns error changeset with duplicate email" do
      user = user_fixture()
      attrs = %{email: user.email, password: valid_user_password(), name: "Dupe"}
      assert {:error, changeset} = Accounts.create_user(attrs)
      assert %{email: ["has already been taken"]} = errors_on(changeset)
    end

    test "returns error changeset with invalid role" do
      attrs = %{email: unique_user_email(), password: valid_user_password(), role: "superadmin"}
      assert {:error, changeset} = Accounts.create_user(attrs)
      assert %{role: ["is invalid"]} = errors_on(changeset)
    end
  end

  describe "get_user/1 and get_user!/1" do
    test "get_user returns user when exists" do
      user = user_fixture()
      assert found = Accounts.get_user(user.id)
      assert found.id == user.id
    end

    test "get_user returns nil for non-existent id" do
      assert is_nil(Accounts.get_user(0))
    end

    test "get_user! returns user when exists" do
      user = user_fixture()
      assert found = Accounts.get_user!(user.id)
      assert found.id == user.id
    end

    test "get_user! raises for non-existent id" do
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_user!(0) end
    end
  end

  describe "get_user_by_email/1" do
    test "returns the user when email exists" do
      user = user_fixture()
      assert found = Accounts.get_user_by_email(user.email)
      assert found.id == user.id
    end

    test "returns nil when email does not exist" do
      assert is_nil(Accounts.get_user_by_email("nonexistent@example.com"))
    end
  end

  describe "get_user_by_email_and_password/2" do
    test "returns the user with correct credentials" do
      user = user_fixture()
      assert found = Accounts.get_user_by_email_and_password(user.email, valid_user_password())
      assert found.id == user.id
    end

    test "returns nil with wrong password" do
      user = user_fixture()
      assert is_nil(Accounts.get_user_by_email_and_password(user.email, "wrongpassword1"))
    end

    test "returns nil with non-existent email" do
      assert is_nil(Accounts.get_user_by_email_and_password("nobody@example.com", "somepass1"))
    end
  end

  describe "create_imported_user/1" do
    test "creates a user without requiring a password" do
      attrs = %{email: unique_user_email(), name: "Imported User", role: "user"}
      assert {:ok, user} = Accounts.create_imported_user(attrs)
      assert user.email == attrs.email
      assert user.name == "Imported User"
      assert is_nil(user.hashed_password)
    end

    test "returns error with duplicate email" do
      existing = user_fixture()
      assert {:error, changeset} = Accounts.create_imported_user(%{email: existing.email})
      assert %{email: _} = errors_on(changeset)
    end
  end

  describe "update_user/2" do
    test "updates user attributes" do
      user = user_fixture(%{name: "Old Name"})
      assert {:ok, updated} = Accounts.update_user(user, %{name: "New Name"})
      assert updated.name == "New Name"
    end

    test "returns error changeset with invalid data" do
      user = user_fixture()
      assert {:error, changeset} = Accounts.update_user(user, %{email: "not-an-email"})
      assert %{email: _} = errors_on(changeset)
    end
  end

  describe "generate_user_session_token/1 and get_user_by_session_token/1" do
    test "generates a token and retrieves the user" do
      user = user_fixture()
      token = Accounts.generate_user_session_token(user)
      assert is_binary(token)

      assert found = Accounts.get_user_by_session_token(token)
      assert found.id == user.id
    end

    test "returns nil for invalid token" do
      assert is_nil(Accounts.get_user_by_session_token(:crypto.strong_rand_bytes(32)))
    end

    test "returns nil after token deletion" do
      user = user_fixture()
      token = Accounts.generate_user_session_token(user)
      Accounts.delete_user_session_token(token)

      assert is_nil(Accounts.get_user_by_session_token(token))
    end

    test "delete_all_user_tokens removes all tokens for a user" do
      user = user_fixture()
      _t1 = Accounts.generate_user_session_token(user)
      _t2 = Accounts.generate_user_session_token(user)
      assert :ok = Accounts.delete_all_user_tokens(user)

      # Both tokens should be invalid now
      assert is_nil(Accounts.get_user_by_session_token(_t1))
      assert is_nil(Accounts.get_user_by_session_token(_t2))
    end
  end

  describe "onboarding" do
    test "complete_onboarding_step adds a new step" do
      user = user_fixture()
      assert {:ok, updated} = Accounts.complete_onboarding_step(user, "import_xlsx")
      assert "import_xlsx" in SkillsetEvaluator.Accounts.User.completed_steps(updated)
    end

    test "complete_onboarding_step is idempotent" do
      user = user_fixture()
      {:ok, user} = Accounts.complete_onboarding_step(user, "import_xlsx")
      {:ok, user} = Accounts.complete_onboarding_step(user, "import_xlsx")
      assert SkillsetEvaluator.Accounts.User.completed_steps(user) == ["import_xlsx"]
    end

    test "dismiss_onboarding sets dismissed flag" do
      user = user_fixture()
      assert {:ok, updated} = Accounts.dismiss_onboarding(user)
      assert updated.onboarding_dismissed == true
    end

    test "reset_onboarding clears steps and dismissed flag" do
      user = user_fixture()
      {:ok, user} = Accounts.complete_onboarding_step(user, "import_xlsx")
      {:ok, user} = Accounts.dismiss_onboarding(user)

      assert {:ok, reset} = Accounts.reset_onboarding(user)
      assert SkillsetEvaluator.Accounts.User.completed_steps(reset) == []
      assert reset.onboarding_dismissed == false
    end
  end

  describe "get_or_create_user_from_microsoft/1" do
    test "creates a new user from Microsoft auth" do
      auth = %{uid: "ms-uid-001", info: %{email: unique_user_email(), name: "MS User"}}
      assert {:ok, user} = Accounts.get_or_create_user_from_microsoft(auth)
      assert user.microsoft_uid == "ms-uid-001"
      assert user.name == "MS User"
    end

    test "returns existing user if microsoft_uid already registered" do
      existing = user_fixture(%{name: "Existing MS User"})

      # First call to link the uid
      existing_updated =
        existing
        |> Ecto.Changeset.change(%{microsoft_uid: "ms-uid-existing"})
        |> SkillsetEvaluator.Repo.update!()

      auth = %{uid: "ms-uid-existing", info: %{email: existing.email, name: "New Name"}}
      assert {:ok, found} = Accounts.get_or_create_user_from_microsoft(auth)
      assert found.id == existing_updated.id
    end

    test "links microsoft_uid to existing user with matching email" do
      existing = user_fixture(%{name: "Existing Email User"})
      auth = %{uid: "ms-new-uid", info: %{email: existing.email, name: "Same Email"}}
      assert {:ok, updated} = Accounts.get_or_create_user_from_microsoft(auth)
      assert updated.id == existing.id
      assert updated.microsoft_uid == "ms-new-uid"
    end

    test "falls back to uid@microsoft.com when email is nil" do
      auth = %{uid: "ms-noemail-uid", info: %{email: nil, name: "No Email"}}
      assert {:ok, user} = Accounts.get_or_create_user_from_microsoft(auth)
      assert user.email == "ms-noemail-uid@microsoft.com"
    end
  end

  describe "list_users_by_team/1" do
    test "returns active users belonging to the given team" do
      team = team_fixture()
      user1 = user_fixture(%{name: "TeamUser1"})
      user2 = user_fixture(%{name: "TeamUser2"})
      _other = user_fixture(%{name: "OtherUser"})

      SkillsetEvaluator.Teams.add_user_to_team(user1.id, team.id)
      SkillsetEvaluator.Teams.add_user_to_team(user2.id, team.id)

      result = Accounts.list_users_by_team(team.id)
      ids = Enum.map(result, & &1.id)

      assert user1.id in ids
      assert user2.id in ids
      assert length(ids) == 2
    end

    test "returns empty list when no users belong to the team" do
      team = team_fixture()
      assert Accounts.list_users_by_team(team.id) == []
    end
  end
end
