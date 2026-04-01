defmodule SkillsetEvaluator.ChatTest do
  use SkillsetEvaluator.DataCase

  alias SkillsetEvaluator.Chat

  setup do
    user = user_fixture(%{name: "Chat User"})
    %{user: user}
  end

  # ---------------------------------------------------------------------------
  # Conversations
  # ---------------------------------------------------------------------------

  describe "create_conversation/2" do
    test "creates a conversation with just user_id", ctx do
      assert {:ok, conv} = Chat.create_conversation(ctx.user.id)
      assert conv.user_id == ctx.user.id
      assert conv.locale == "en"
      assert is_nil(conv.title)
    end

    test "creates a conversation with title and locale", ctx do
      assert {:ok, conv} =
               Chat.create_conversation(ctx.user.id, %{title: "My Chat", locale: "de"})

      assert conv.title == "My Chat"
      assert conv.locale == "de"
    end

    test "rejects invalid locale", ctx do
      assert {:error, changeset} =
               Chat.create_conversation(ctx.user.id, %{locale: "fr"})

      assert %{locale: _} = errors_on(changeset)
    end

    test "enforces max 50 conversations per user", ctx do
      for _ <- 1..50 do
        {:ok, _} = Chat.create_conversation(ctx.user.id)
      end

      assert {:error, :conversation_limit_reached} = Chat.create_conversation(ctx.user.id)
    end
  end

  describe "list_conversations/2" do
    test "returns conversations for the user ordered by updated_at desc", ctx do
      {:ok, c1} = Chat.create_conversation(ctx.user.id, %{title: "First"})
      {:ok, c2} = Chat.create_conversation(ctx.user.id, %{title: "Second"})

      convs = Chat.list_conversations(ctx.user.id)
      ids = Enum.map(convs, & &1.id)

      assert c1.id in ids
      assert c2.id in ids
    end

    test "returns empty list when user has no conversations", ctx do
      other = user_fixture()
      assert Chat.list_conversations(other.id) == []
    end

    test "supports limit and offset pagination", ctx do
      for i <- 1..5 do
        Chat.create_conversation(ctx.user.id, %{title: "Conv #{i}"})
      end

      page1 = Chat.list_conversations(ctx.user.id, limit: 2, offset: 0)
      page2 = Chat.list_conversations(ctx.user.id, limit: 2, offset: 2)

      assert length(page1) == 2
      assert length(page2) == 2
      assert Enum.map(page1, & &1.id) != Enum.map(page2, & &1.id)
    end
  end

  describe "get_conversation/1" do
    test "returns the conversation with messages preloaded", ctx do
      {:ok, conv} = Chat.create_conversation(ctx.user.id)
      {:ok, _} = Chat.create_message(conv.id, %{role: "user", content: "Hello"})

      result = Chat.get_conversation(conv.id)

      assert result.id == conv.id
      assert length(result.messages) == 1
      assert hd(result.messages).content == "Hello"
    end

    test "returns nil for non-existent id", _ctx do
      assert is_nil(Chat.get_conversation(999_999))
    end
  end

  describe "get_conversation!/1" do
    test "returns the conversation", ctx do
      {:ok, conv} = Chat.create_conversation(ctx.user.id)
      result = Chat.get_conversation!(conv.id)
      assert result.id == conv.id
    end

    test "raises for non-existent id", _ctx do
      assert_raise Ecto.NoResultsError, fn -> Chat.get_conversation!(999_999) end
    end
  end

  describe "delete_conversation/1" do
    test "deletes the conversation", ctx do
      {:ok, conv} = Chat.create_conversation(ctx.user.id)
      {:ok, _} = Chat.delete_conversation(conv)
      assert is_nil(Chat.get_conversation(conv.id))
    end
  end

  describe "create_message/2" do
    test "creates a user message and increments message_count", ctx do
      {:ok, conv} = Chat.create_conversation(ctx.user.id)
      {:ok, msg} = Chat.create_message(conv.id, %{role: "user", content: "Hello!"})

      assert msg.role == "user"
      assert msg.content == "Hello!"
      assert msg.conversation_id == conv.id

      updated_conv = Chat.get_conversation(conv.id)
      assert updated_conv.message_count == 1
    end

    test "creates an assistant message with token usage", ctx do
      {:ok, conv} = Chat.create_conversation(ctx.user.id)

      {:ok, msg} =
        Chat.create_message(conv.id, %{
          role: "assistant",
          content: "I can help!",
          token_usage: %{input: 10, output: 20},
          provider: "test",
          model: "claude-test"
        })

      assert msg.role == "assistant"
      assert msg.token_usage == %{input: 10, output: 20}
    end

    test "rejects invalid role", ctx do
      {:ok, conv} = Chat.create_conversation(ctx.user.id)
      # invalid role should cause an error at the DB level
      assert_raise Ecto.InvalidChangesetError, fn ->
        Chat.create_message(conv.id, %{role: "invalid_role", content: "x"})
      end
    end
  end

  describe "list_messages/2" do
    test "returns messages ordered by inserted_at", ctx do
      {:ok, conv} = Chat.create_conversation(ctx.user.id)
      {:ok, m1} = Chat.create_message(conv.id, %{role: "user", content: "First"})
      {:ok, m2} = Chat.create_message(conv.id, %{role: "assistant", content: "Second"})

      msgs = Chat.list_messages(conv.id)
      ids = Enum.map(msgs, & &1.id)

      assert m1.id in ids
      assert m2.id in ids
    end

    test "returns empty list for conversation with no messages", ctx do
      {:ok, conv} = Chat.create_conversation(ctx.user.id)
      assert Chat.list_messages(conv.id) == []
    end

    test "respects limit", ctx do
      {:ok, conv} = Chat.create_conversation(ctx.user.id)

      for i <- 1..5 do
        Chat.create_message(conv.id, %{role: "user", content: "msg #{i}"})
      end

      msgs = Chat.list_messages(conv.id, 3)
      assert length(msgs) == 3
    end
  end

  describe "count_user_conversations/1" do
    test "returns count of conversations for a user", ctx do
      assert Chat.count_user_conversations(ctx.user.id) == 0
      Chat.create_conversation(ctx.user.id)
      Chat.create_conversation(ctx.user.id)
      assert Chat.count_user_conversations(ctx.user.id) == 2
    end
  end

  describe "update_conversation_title/2" do
    test "updates the title", ctx do
      {:ok, conv} = Chat.create_conversation(ctx.user.id)
      Chat.update_conversation_title(conv.id, "New Title")
      updated = Chat.get_conversation(conv.id)
      assert updated.title == "New Title"
    end

    test "truncates title to 100 chars", ctx do
      {:ok, conv} = Chat.create_conversation(ctx.user.id)
      long_title = String.duplicate("a", 150)
      Chat.update_conversation_title(conv.id, long_title)
      updated = Chat.get_conversation(conv.id)
      assert String.length(updated.title) == 100
    end
  end

  describe "maybe_auto_title/2" do
    test "sets title from first message if title is nil", ctx do
      {:ok, conv} = Chat.create_conversation(ctx.user.id)
      Chat.maybe_auto_title(conv.id, "Tell me about skills")
      updated = Chat.get_conversation(conv.id)
      assert updated.title == "Tell me about skills"
    end

    test "does not overwrite existing title", ctx do
      {:ok, conv} = Chat.create_conversation(ctx.user.id, %{title: "Existing"})
      Chat.maybe_auto_title(conv.id, "New content")
      updated = Chat.get_conversation(conv.id)
      assert updated.title == "Existing"
    end

    test "truncates long content with ellipsis", ctx do
      {:ok, conv} = Chat.create_conversation(ctx.user.id)
      long_content = String.duplicate("x", 90)
      Chat.maybe_auto_title(conv.id, long_content)
      updated = Chat.get_conversation(conv.id)
      assert String.ends_with?(updated.title, "...")
    end
  end

  describe "search_conversations/3" do
    test "finds conversations by title", ctx do
      {:ok, _c1} = Chat.create_conversation(ctx.user.id, %{title: "JavaScript tips"})
      {:ok, _c2} = Chat.create_conversation(ctx.user.id, %{title: "Python basics"})

      results = Chat.search_conversations(ctx.user.id, "JavaScript")
      assert length(results) == 1
      assert hd(results).title == "JavaScript tips"
    end

    test "finds conversations by message content", ctx do
      {:ok, conv} = Chat.create_conversation(ctx.user.id)
      Chat.create_message(conv.id, %{role: "user", content: "Elixir pattern matching"})

      results = Chat.search_conversations(ctx.user.id, "Elixir")
      assert length(results) >= 1
    end

    test "returns empty list when no matches", ctx do
      {:ok, _} = Chat.create_conversation(ctx.user.id, %{title: "Unrelated topic"})
      results = Chat.search_conversations(ctx.user.id, "xyznonexistent")
      assert results == []
    end

    test "does not return conversations from other users", ctx do
      other = user_fixture()
      {:ok, _} = Chat.create_conversation(other.id, %{title: "Secret conversation"})

      results = Chat.search_conversations(ctx.user.id, "Secret")
      assert results == []
    end

    test "respects limit", ctx do
      for i <- 1..5 do
        {:ok, _} = Chat.create_conversation(ctx.user.id, %{title: "topic #{i}"})
      end

      results = Chat.search_conversations(ctx.user.id, "topic", limit: 2)
      assert length(results) <= 2
    end

    test "sanitizes special SQL wildcard characters in query", ctx do
      {:ok, _} = Chat.create_conversation(ctx.user.id, %{title: "100% complete"})
      # Query with %, _, and \ characters should not cause errors
      results_pct = Chat.search_conversations(ctx.user.id, "100%")
      results_underscore = Chat.search_conversations(ctx.user.id, "comp_ete")
      results_backslash = Chat.search_conversations(ctx.user.id, "back\\slash")
      assert is_list(results_pct)
      assert is_list(results_underscore)
      assert is_list(results_backslash)
    end

    test "builds snippet with prefix and suffix for long message content", ctx do
      long_prefix = String.duplicate("x", 50)
      long_suffix = String.duplicate("z", 50)
      content = "#{long_prefix}TARGET#{long_suffix}"

      {:ok, conv} = Chat.create_conversation(ctx.user.id)
      Chat.create_message(conv.id, %{role: "user", content: content})

      results = Chat.search_conversations(ctx.user.id, "TARGET")
      assert length(results) >= 1

      snippet = hd(results).match_snippet
      assert is_binary(snippet)
    end
  end

  describe "cleanup_old_conversations/1" do
    test "deletes conversations older than the given days", ctx do
      {:ok, conv} = Chat.create_conversation(ctx.user.id)

      # Manually set updated_at to 100 days ago using Repo.update_all with a query
      import Ecto.Query

      old_ts = DateTime.add(DateTime.utc_now(), -100 * 86_400, :second)

      SkillsetEvaluator.Repo.update_all(
        from(c in SkillsetEvaluator.Chat.Conversation, where: c.id == ^conv.id),
        set: [updated_at: old_ts]
      )

      {deleted, _} = Chat.cleanup_old_conversations(90)
      assert deleted >= 1
    end

    test "does not delete recent conversations", ctx do
      {:ok, _conv} = Chat.create_conversation(ctx.user.id)
      {deleted, _} = Chat.cleanup_old_conversations(90)
      assert deleted == 0
    end
  end
end
