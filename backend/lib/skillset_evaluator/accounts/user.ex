defmodule SkillsetEvaluator.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :email, :string
    field :hashed_password, :string
    field :password, :string, virtual: true, redact: true
    field :role, :string, default: "user"
    field :name, :string
    field :location, :string
    field :microsoft_uid, :string
    field :active, :boolean, default: true
    field :job_title, :string
    field :confirmed_at, :utc_datetime
    field :onboarding_completed_steps, :string, default: "[]"
    field :onboarding_dismissed, :boolean, default: false

    belongs_to :team, SkillsetEvaluator.Teams.Team

    has_many :evaluations, SkillsetEvaluator.Evaluations.Evaluation

    timestamps(type: :utc_datetime)
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [
      :email,
      :name,
      :role,
      :location,
      :microsoft_uid,
      :active,
      :job_title,
      :confirmed_at,
      :team_id
    ])
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
    |> unique_constraint(:email)
    |> validate_inclusion(:role, ["user", "manager", "admin"])
  end

  def registration_changeset(user, attrs) do
    user
    |> changeset(attrs)
    |> cast(attrs, [:password])
    |> validate_required([:password])
    |> validate_length(:password, min: 8, max: 72)
    |> hash_password()
  end

  def onboarding_changeset(user, attrs) do
    cast(user, attrs, [:onboarding_completed_steps, :onboarding_dismissed])
  end

  @doc """
  Parses the JSON string of completed onboarding steps into a list of strings.
  """
  def completed_steps(%__MODULE__{onboarding_completed_steps: steps}) do
    case Jason.decode(steps || "[]") do
      {:ok, list} when is_list(list) -> list
      _ -> []
    end
  end

  @doc """
  Returns a changeset that appends step_id to the completed steps (deduplicating).
  """
  def add_completed_step(user, step_id) do
    current = completed_steps(user)
    new_steps = Enum.uniq(current ++ [step_id])
    onboarding_changeset(user, %{onboarding_completed_steps: Jason.encode!(new_steps)})
  end

  defp hash_password(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: password}} ->
        changeset
        |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(password))
        |> delete_change(:password)

      _ ->
        changeset
    end
  end

  def valid_password?(%__MODULE__{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    Bcrypt.no_user_verify()
    false
  end
end
