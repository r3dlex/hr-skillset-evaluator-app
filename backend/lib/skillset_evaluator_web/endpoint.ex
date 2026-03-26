defmodule SkillsetEvaluatorWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :skillset_evaluator

  @session_options [
    store: :cookie,
    key: "_skillset_evaluator_key",
    signing_salt: "hR5k1lS3t",
    same_site: "Lax"
  ]

  plug Plug.Static,
    at: "/",
    from: :skillset_evaluator,
    gzip: false,
    only: SkillsetEvaluatorWeb.static_paths()

  if code_reloading? do
    plug Phoenix.CodeReloader
  end

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library(),
    length: 50_000_000

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug SkillsetEvaluatorWeb.Router
end
