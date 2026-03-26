defmodule SkillsetEvaluatorWeb.Plugs.Auth do
  @moduledoc """
  Authentication plugs for the SkillsetEvaluator application.
  """

  import Plug.Conn
  import Phoenix.Controller

  alias SkillsetEvaluator.Accounts

  def init(:fetch_current_user), do: :fetch_current_user
  def init(:require_authenticated_user), do: :require_authenticated_user
  def init({:require_role, role}), do: {:require_role, role}

  def call(conn, :fetch_current_user) do
    fetch_current_user(conn)
  end

  def call(conn, :require_authenticated_user) do
    require_authenticated_user(conn)
  end

  def call(conn, {:require_role, role}) do
    require_role(conn, role)
  end

  defp fetch_current_user(conn) do
    token = get_session(conn, :user_token)

    user =
      if token do
        Accounts.get_user_by_session_token(token)
      end

    assign(conn, :current_user, user)
  end

  defp require_authenticated_user(conn) do
    if conn.assigns[:current_user] do
      conn
    else
      conn
      |> put_status(:unauthorized)
      |> json(%{error: "You must be logged in to access this resource."})
      |> halt()
    end
  end

  defp require_role(conn, role) do
    user = conn.assigns[:current_user]

    cond do
      is_nil(user) ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "You must be logged in to access this resource."})
        |> halt()

      user.role == role or user.role == "admin" ->
        conn

      true ->
        conn
        |> put_status(:forbidden)
        |> json(%{error: "You do not have permission to access this resource."})
        |> halt()
    end
  end
end
