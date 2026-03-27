defmodule SkillsetEvaluator.Chat do
  @moduledoc """
  The Chat context — manages conversations and messages.
  """

  import Ecto.Query

  alias SkillsetEvaluator.Repo
  alias SkillsetEvaluator.Chat.{Conversation, Message}

  @max_conversations_per_user 50

  ## Conversations

  @doc """
  Creates a new conversation for the given user.
  Enforces the per-user conversation limit.
  """
  def create_conversation(user_id, attrs \\ %{}) do
    count = count_user_conversations(user_id)

    if count >= @max_conversations_per_user do
      {:error, :conversation_limit_reached}
    else
      attrs = Map.merge(attrs, %{user_id: user_id})

      %Conversation{}
      |> Conversation.changeset(attrs)
      |> Repo.insert()
    end
  end

  @doc """
  Lists conversations for a user, ordered by updated_at DESC.
  Supports pagination via :offset and :limit options.
  """
  def list_conversations(user_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 20)
    offset = Keyword.get(opts, :offset, 0)

    Conversation
    |> where([c], c.user_id == ^user_id)
    |> order_by([c], desc: c.updated_at)
    |> limit(^limit)
    |> offset(^offset)
    |> Repo.all()
  end

  @doc """
  Searches conversations by title and message content.
  Returns conversations matching the query string with relevance scoring.
  """
  def search_conversations(user_id, query, opts \\ []) do
    limit = Keyword.get(opts, :limit, 20)
    search_term = "%#{sanitize_search(query)}%"

    # Find conversations where title or any message content matches
    title_matches =
      Conversation
      |> where([c], c.user_id == ^user_id)
      |> where([c], like(fragment("lower(?)", c.title), ^String.downcase(search_term)))
      |> select([c], %{id: c.id, match_type: "title", match_preview: c.title})
      |> Repo.all()

    content_matches =
      Message
      |> join(:inner, [m], c in Conversation, on: m.conversation_id == c.id)
      |> where([m, c], c.user_id == ^user_id)
      |> where([m, _c], like(fragment("lower(?)", m.content), ^String.downcase(search_term)))
      |> select([m, c], %{id: c.id, match_type: m.role, match_preview: m.content})
      |> distinct([m, c], c.id)
      |> Repo.all()

    # Merge and deduplicate, preferring title matches
    matched_ids =
      (title_matches ++ content_matches)
      |> Enum.uniq_by(& &1.id)
      |> Enum.map(& &1.id)
      |> Enum.take(limit)

    # Build a preview map: conversation_id -> best matching snippet
    preview_map =
      (title_matches ++ content_matches)
      |> Enum.group_by(& &1.id)
      |> Enum.map(fn {id, matches} ->
        best = Enum.find(matches, fn m -> m.match_type == "title" end) || List.first(matches)
        snippet = build_snippet(best.match_preview, query)
        {id, %{match_type: best.match_type, snippet: snippet}}
      end)
      |> Map.new()

    # Fetch full conversations for matched IDs, preserving relevance order
    if matched_ids == [] do
      []
    else
      convs =
        Conversation
        |> where([c], c.id in ^matched_ids)
        |> Repo.all()
        |> Map.new(&{&1.id, &1})

      Enum.flat_map(matched_ids, fn id ->
        case Map.get(convs, id) do
          nil -> []
          conv ->
            preview = Map.get(preview_map, id, %{match_type: "title", snippet: ""})
            [Map.merge(Map.from_struct(conv), %{match_snippet: preview.snippet, match_type: preview.match_type})]
        end
      end)
    end
  end

  defp sanitize_search(query) do
    query
    |> String.replace(~r/[%_\\]/, fn
      "%" -> "\\%"
      "_" -> "\\_"
      "\\" -> "\\\\"
    end)
    |> String.trim()
  end

  defp build_snippet(text, _query) when is_nil(text) or text == "", do: ""

  defp build_snippet(text, query) do
    downcase_text = String.downcase(text)
    downcase_query = String.downcase(query)

    case :binary.match(downcase_text, downcase_query) do
      {start, _len} ->
        # Show ~40 chars before and after the match
        snippet_start = max(0, start - 40)
        snippet_end = min(String.length(text), start + String.length(query) + 40)
        snippet = String.slice(text, snippet_start, snippet_end - snippet_start)

        prefix = if snippet_start > 0, do: "...", else: ""
        suffix = if snippet_end < String.length(text), do: "...", else: ""

        "#{prefix}#{snippet}#{suffix}"

      :nomatch ->
        String.slice(text, 0, 80)
    end
  end

  @doc """
  Gets a conversation by ID with messages preloaded.
  """
  def get_conversation(id) do
    Conversation
    |> Repo.get(id)
    |> case do
      nil -> nil
      conv -> Repo.preload(conv, messages: from(m in Message, order_by: m.inserted_at))
    end
  end

  @doc """
  Gets a conversation by ID, raises if not found.
  """
  def get_conversation!(id) do
    Conversation
    |> Repo.get!(id)
    |> Repo.preload(messages: from(m in Message, order_by: m.inserted_at))
  end

  @doc """
  Deletes a conversation and all its messages.
  """
  def delete_conversation(%Conversation{} = conversation) do
    Repo.delete(conversation)
  end

  @doc """
  Creates a message in a conversation and increments message_count.
  """
  def create_message(conversation_id, attrs) do
    Repo.transaction(fn ->
      attrs = Map.put(attrs, :conversation_id, conversation_id)

      message =
        %Message{}
        |> Message.changeset(attrs)
        |> Repo.insert!()

      # Increment message_count and touch updated_at
      from(c in Conversation,
        where: c.id == ^conversation_id,
        update: [inc: [message_count: 1], set: [updated_at: ^DateTime.utc_now()]]
      )
      |> Repo.update_all([])

      message
    end)
  end

  @doc """
  Lists messages for a conversation, ordered by inserted_at.
  """
  def list_messages(conversation_id, limit \\ 100) do
    Message
    |> where([m], m.conversation_id == ^conversation_id)
    |> order_by([m], m.inserted_at)
    |> limit(^limit)
    |> Repo.all()
  end

  @doc """
  Returns the count of conversations for a user.
  """
  def count_user_conversations(user_id) do
    Conversation
    |> where([c], c.user_id == ^user_id)
    |> Repo.aggregate(:count)
  end

  @doc """
  Deletes conversations older than the given number of days.
  """
  def cleanup_old_conversations(days \\ 90) do
    cutoff = DateTime.utc_now() |> DateTime.add(-days * 86_400, :second)

    from(c in Conversation, where: c.updated_at < ^cutoff)
    |> Repo.delete_all()
  end
end
