defmodule SkillsetEvaluator.Chat.Conversation do
  use Ecto.Schema
  import Ecto.Changeset

  schema "chat_conversations" do
    field :title, :string
    field :locale, :string, default: "en"
    field :message_count, :integer, default: 0

    belongs_to :user, SkillsetEvaluator.Accounts.User
    has_many :messages, SkillsetEvaluator.Chat.Message

    timestamps(type: :utc_datetime)
  end

  def changeset(conversation, attrs) do
    conversation
    |> cast(attrs, [:user_id, :title, :locale, :message_count])
    |> validate_required([:user_id])
    |> validate_inclusion(:locale, ["en", "de", "zh"])
    |> validate_length(:title, max: 100)
    |> foreign_key_constraint(:user_id)
  end
end
