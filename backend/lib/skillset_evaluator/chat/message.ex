defmodule SkillsetEvaluator.Chat.Message do
  use Ecto.Schema
  import Ecto.Changeset

  schema "chat_messages" do
    field :role, :string
    field :content, :string
    field :token_usage, :map, default: %{}
    field :provider, :string
    field :model, :string

    belongs_to :conversation, SkillsetEvaluator.Chat.Conversation

    timestamps(type: :utc_datetime, updated_at: false)
  end

  def changeset(message, attrs) do
    message
    |> cast(attrs, [:conversation_id, :role, :content, :token_usage, :provider, :model])
    |> validate_required([:conversation_id, :role, :content])
    |> validate_inclusion(:role, ["user", "assistant", "system"])
    |> foreign_key_constraint(:conversation_id)
  end
end
