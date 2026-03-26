defmodule SkillsetEvaluator.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query
  alias SkillsetEvaluator.Repo
  alias SkillsetEvaluator.Accounts.{User, UserToken}

  ## User queries

  def get_user(id), do: Repo.get(User, id)

  def get_user!(id), do: Repo.get!(User, id)

  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = get_user_by_email(email)
    if User.valid_password?(user, password), do: user
  end

  def authenticate_user(email, password) do
    case get_user_by_email_and_password(email, password) do
      %User{} = user -> {:ok, user}
      nil -> {:error, :invalid_credentials}
    end
  end

  def list_users_by_team(team_id) do
    User
    |> where([u], u.team_id == ^team_id)
    |> where([u], u.active == true)
    |> Repo.all()
  end

  ## User registration

  def create_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  ## Session tokens

  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  def delete_user_session_token(token) do
    Repo.delete_all(UserToken.by_token_and_context_query(token, "session"))
    :ok
  end

  def delete_all_user_tokens(user) do
    Repo.delete_all(UserToken.by_user_and_contexts_query(user, :all))
    :ok
  end

  ## Microsoft SSO

  def get_or_create_user_from_microsoft(%{uid: uid, info: info}) do
    case Repo.get_by(User, microsoft_uid: uid) do
      %User{} = user ->
        {:ok, user}

      nil ->
        email = info.email || "#{uid}@microsoft.com"

        case get_user_by_email(email) do
          %User{} = user ->
            user
            |> User.changeset(%{microsoft_uid: uid})
            |> Repo.update()

          nil ->
            %User{}
            |> User.changeset(%{
              email: email,
              name: info.name,
              microsoft_uid: uid,
              confirmed_at: DateTime.utc_now()
            })
            |> Repo.insert()
        end
    end
  end
end
