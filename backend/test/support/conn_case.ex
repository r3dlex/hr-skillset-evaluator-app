defmodule SkillsetEvaluatorWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      import Plug.Conn
      import Phoenix.ConnTest
      import SkillsetEvaluatorWeb.ConnCase
      import SkillsetEvaluator.Fixtures

      alias SkillsetEvaluatorWeb.Router.Helpers, as: Routes

      @endpoint SkillsetEvaluatorWeb.Endpoint
    end
  end

  setup tags do
    SkillsetEvaluator.DataCase.setup_sandbox(tags)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  @doc """
  Setup helper that logs in a user for controller tests.
  """
  def log_in_user(conn, user) do
    token = SkillsetEvaluator.Accounts.generate_user_session_token(user)

    conn
    |> Phoenix.ConnTest.init_test_session(%{})
    |> Plug.Conn.put_session(:user_token, token)
  end
end
