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
  end

  describe "list_users_by_team/1" do
    test "returns active users belonging to the given team" do
      team = team_fixture()
      user1 = user_fixture(%{team_id: team.id, name: "TeamUser1"})
      user2 = user_fixture(%{team_id: team.id, name: "TeamUser2"})
      _other = user_fixture(%{name: "OtherUser"})

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
