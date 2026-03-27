defmodule SkillsetEvaluatorWeb.Router do
  use SkillsetEvaluatorWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
    plug :fetch_session
    plug SkillsetEvaluatorWeb.Plugs.Auth, :fetch_current_user
  end

  pipeline :require_auth do
    plug SkillsetEvaluatorWeb.Plugs.Auth, :require_authenticated_user
  end

  pipeline :require_manager do
    plug SkillsetEvaluatorWeb.Plugs.Auth, :require_authenticated_user
    plug SkillsetEvaluatorWeb.Plugs.Auth, {:require_role, "manager"}
  end

  # Health check (public, no auth)
  scope "/api", SkillsetEvaluatorWeb do
    pipe_through :api

    get "/health", HealthController, :show
  end

  # Public auth routes
  scope "/api/auth", SkillsetEvaluatorWeb do
    pipe_through :api

    post "/login", AuthController, :login
    delete "/logout", AuthController, :logout
    get "/microsoft", AuthController, :microsoft_request
    get "/microsoft/callback", AuthController, :microsoft_callback
    post "/microsoft/callback", AuthController, :microsoft_callback
  end

  # Authenticated routes
  scope "/api", SkillsetEvaluatorWeb do
    pipe_through [:api, :require_auth]

    get "/me", MeController, :show
    put "/me/onboarding", MeController, :update_onboarding
    delete "/me/onboarding", MeController, :dismiss_onboarding
    resources "/teams", TeamController, only: [:index, :show]
    resources "/skillsets", SkillsetController, only: [:index, :show]

    get "/periods", PeriodsController, :index
    get "/evaluations", EvaluationController, :index
    put "/evaluations/self", EvaluationController, :update_self_scores

    get "/radar", RadarController, :show
    get "/gap-analysis", GapAnalysisController, :show
  end

  # Manager-only routes
  scope "/api", SkillsetEvaluatorWeb do
    pipe_through [:api, :require_manager]

    resources "/skillsets", SkillsetController, only: [:create]
    put "/evaluations/manager", EvaluationController, :update_manager_scores
    post "/import", ImportController, :create
    get "/export", ExportController, :show
  end

  # SPA catch-all: serve index.html for all non-API routes
  scope "/", SkillsetEvaluatorWeb do
    pipe_through :api

    get "/*path", FallbackController, :index
  end
end
