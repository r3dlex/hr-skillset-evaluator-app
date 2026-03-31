defmodule SkillsetEvaluatorWeb.Plugs.AuthTest do
  use SkillsetEvaluatorWeb.ConnCase

  alias SkillsetEvaluatorWeb.Plugs.Auth
  alias SkillsetEvaluator.Accounts

  describe "init/1" do
    test "returns :fetch_current_user unchanged" do
      assert Auth.init(:fetch_current_user) == :fetch_current_user
    end

    test "returns :require_authenticated_user unchanged" do
      assert Auth.init(:require_authenticated_user) == :require_authenticated_user
    end

    test "returns {:require_role, role} tuple unchanged" do
      assert Auth.init({:require_role, "manager"}) == {:require_role, "manager"}
      assert Auth.init({:require_role, "admin"}) == {:require_role, "admin"}
    end
  end

  describe "fetch_current_user" do
    test "assigns current_user when valid session token exists", %{conn: conn} do
      user = user_fixture()
      token = Accounts.generate_user_session_token(user)

      conn =
        conn
        |> init_test_session(%{user_token: token})
        |> Auth.call(:fetch_current_user)

      assert conn.assigns.current_user.id == user.id
    end

    test "assigns nil when no session token exists", %{conn: conn} do
      conn =
        conn
        |> init_test_session(%{})
        |> Auth.call(:fetch_current_user)

      assert is_nil(conn.assigns.current_user)
    end

    test "assigns nil when session token is invalid", %{conn: conn} do
      conn =
        conn
        |> init_test_session(%{user_token: :crypto.strong_rand_bytes(32)})
        |> Auth.call(:fetch_current_user)

      assert is_nil(conn.assigns.current_user)
    end
  end

  describe "require_authenticated_user" do
    test "allows request when current_user is set", %{conn: conn} do
      user = user_fixture()

      conn =
        conn
        |> assign(:current_user, user)
        |> Auth.call(:require_authenticated_user)

      refute conn.halted
    end

    test "halts and returns 401 when current_user is nil", %{conn: conn} do
      conn =
        conn
        |> init_test_session(%{})
        |> fetch_flash()
        |> assign(:current_user, nil)
        |> Auth.call(:require_authenticated_user)

      assert conn.halted
      assert conn.status == 401
    end
  end

  describe "require_role" do
    test "allows request when user has the required role", %{conn: conn} do
      manager = manager_fixture()

      conn =
        conn
        |> assign(:current_user, manager)
        |> Auth.call({:require_role, "manager"})

      refute conn.halted
    end

    test "allows request when user is admin regardless of required role", %{conn: conn} do
      admin = user_fixture(%{role: "admin"})

      conn =
        conn
        |> assign(:current_user, admin)
        |> Auth.call({:require_role, "manager"})

      refute conn.halted
    end

    test "halts and returns 403 when user has wrong role", %{conn: conn} do
      user = user_fixture(%{role: "user"})

      conn =
        conn
        |> init_test_session(%{})
        |> fetch_flash()
        |> assign(:current_user, user)
        |> Auth.call({:require_role, "manager"})

      assert conn.halted
      assert conn.status == 403
    end

    test "halts and returns 401 when no user is set", %{conn: conn} do
      conn =
        conn
        |> init_test_session(%{})
        |> fetch_flash()
        |> assign(:current_user, nil)
        |> Auth.call({:require_role, "manager"})

      assert conn.halted
      assert conn.status == 401
    end
  end
end
