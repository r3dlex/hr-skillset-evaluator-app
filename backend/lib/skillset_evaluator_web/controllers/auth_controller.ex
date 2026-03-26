defmodule SkillsetEvaluatorWeb.AuthController do
  use SkillsetEvaluatorWeb, :controller

  alias SkillsetEvaluator.Accounts
  plug Ueberauth, [] when action in [:microsoft_request, :microsoft_callback]

  def login(conn, %{"email" => email, "password" => password}) do
    case Accounts.authenticate_user(email, password) do
      {:ok, user} ->
        token = Accounts.generate_user_session_token(user)

        conn
        |> put_session(:user_token, token)
        |> put_status(:ok)
        |> render(:user, user: user)

      {:error, :invalid_credentials} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Invalid email or password."})
    end
  end

  def logout(conn, _params) do
    token = get_session(conn, :user_token)

    if token do
      Accounts.delete_user_session_token(token)
    end

    conn
    |> clear_session()
    |> put_status(:ok)
    |> json(%{message: "Logged out successfully."})
  end

  def microsoft_request(conn, _params) do
    # Ueberauth handles the redirect automatically
    conn
  end

  def microsoft_callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    case Accounts.get_or_create_user_from_microsoft(auth) do
      {:ok, user} ->
        token = Accounts.generate_user_session_token(user)

        conn
        |> put_session(:user_token, token)
        |> put_status(:ok)
        |> render(:user, user: user)

      {:error, _changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "Failed to authenticate with Microsoft."})
    end
  end

  def microsoft_callback(%{assigns: %{ueberauth_failure: _failure}} = conn, _params) do
    conn
    |> put_status(:unauthorized)
    |> json(%{error: "Microsoft authentication failed."})
  end
end
