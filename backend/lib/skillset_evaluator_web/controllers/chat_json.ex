defmodule SkillsetEvaluatorWeb.ChatJSON do
  alias SkillsetEvaluator.Chat.{Conversation, Message}

  def index(%{conversations: conversations}) do
    %{data: Enum.map(conversations, &conversation_data/1)}
  end

  def show(%{conversation: conversation}) do
    %{data: conversation_with_messages(conversation)}
  end

  def created(%{conversation: conversation}) do
    %{data: conversation_data(conversation)}
  end

  def message(%{message: message}) do
    %{data: message_data(message)}
  end

  def conversation_data(%Conversation{} = conv) do
    %{
      id: conv.id,
      title: conv.title,
      locale: conv.locale,
      message_count: conv.message_count,
      inserted_at: conv.inserted_at,
      updated_at: conv.updated_at
    }
  end

  defp conversation_with_messages(%Conversation{} = conv) do
    messages =
      case conv.messages do
        %Ecto.Association.NotLoaded{} -> []
        msgs -> Enum.map(msgs, &message_data/1)
      end

    %{
      id: conv.id,
      title: conv.title,
      locale: conv.locale,
      message_count: conv.message_count,
      messages: messages,
      inserted_at: conv.inserted_at,
      updated_at: conv.updated_at
    }
  end

  def message_data(%Message{} = msg) do
    %{
      id: msg.id,
      role: msg.role,
      content: msg.content,
      token_usage: msg.token_usage,
      provider: msg.provider,
      model: msg.model,
      inserted_at: msg.inserted_at
    }
  end
end
