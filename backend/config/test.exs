import Config

config :skillset_evaluator, SkillsetEvaluator.Repo,
  database: "/tmp/skillset_evaluator_test.db",
  pool_size: 5,
  pool: Ecto.Adapters.SQL.Sandbox

config :skillset_evaluator, SkillsetEvaluatorWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base:
    "test_only_secret_key_base_that_is_at_least_64_bytes_long_for_testing_purposes_only_ok",
  server: false

config :bcrypt_elixir, :log_rounds, 1

config :logger, level: :warning

config :ueberauth, Ueberauth.Strategy.Microsoft.OAuth,
  client_id: "test_client_id",
  client_secret: "test_client_secret",
  tenant_id: "test_tenant"
