import Config

config :skillset_evaluator, SkillsetEvaluator.Repo,
  database: Path.expand("../data/skillset_evaluator_dev.db", __DIR__),
  pool_size: 5,
  stacktrace: true,
  show_sensitive_data_on_connection_error: true

config :skillset_evaluator, SkillsetEvaluatorWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base:
    "dev_only_secret_key_base_that_is_at_least_64_bytes_long_for_development_use_only_ok",
  watchers: []

config :logger, :console, format: "[$level] $message\n"

config :phoenix, :stacktrace_depth, 20
config :phoenix, :plug_init_mode, :runtime

config :ueberauth, Ueberauth.Strategy.Microsoft.OAuth,
  client_id: System.get_env("MICROSOFT_CLIENT_ID") || "dev_client_id",
  client_secret: System.get_env("MICROSOFT_CLIENT_SECRET") || "dev_client_secret",
  tenant_id: System.get_env("MICROSOFT_TENANT") || "common"
