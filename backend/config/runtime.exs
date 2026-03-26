import Config

if config_env() == :prod do
  database_path =
    System.get_env("DATABASE_PATH") ||
      raise """
      environment variable DATABASE_PATH is missing.
      For example: /data/skillset_evaluator.db
      """

  config :skillset_evaluator, SkillsetEvaluator.Repo,
    database: database_path,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "5"),
    journal_mode: :wal,
    cache_size: -64000,
    temp_store: :memory,
    busy_timeout: 5000

  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "localhost"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :skillset_evaluator, SkillsetEvaluatorWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base

  microsoft_client_id =
    System.get_env("MICROSOFT_CLIENT_ID") ||
      raise "environment variable MICROSOFT_CLIENT_ID is missing."

  microsoft_client_secret =
    System.get_env("MICROSOFT_CLIENT_SECRET") ||
      raise "environment variable MICROSOFT_CLIENT_SECRET is missing."

  microsoft_tenant =
    System.get_env("MICROSOFT_TENANT") || "common"

  config :ueberauth, Ueberauth.Strategy.Microsoft.OAuth,
    client_id: microsoft_client_id,
    client_secret: microsoft_client_secret,
    tenant_id: microsoft_tenant
end
