import Config

config :skillset_evaluator,
  ecto_repos: [SkillsetEvaluator.Repo],
  generators: [timestamp_type: :utc_datetime]

config :skillset_evaluator, SkillsetEvaluatorWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [
    formats: [json: SkillsetEvaluatorWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: SkillsetEvaluator.PubSub

config :skillset_evaluator, :json_library, Jason

config :ueberauth, Ueberauth,
  providers: [
    microsoft: {Ueberauth.Strategy.Microsoft, [callback_methods: ["POST"]]}
  ]

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

import_config "#{config_env()}.exs"
