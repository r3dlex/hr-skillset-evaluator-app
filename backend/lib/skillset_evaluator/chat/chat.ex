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
