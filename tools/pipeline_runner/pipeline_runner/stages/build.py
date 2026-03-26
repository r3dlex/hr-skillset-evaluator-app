"""Build stage: compile frontend assets and create Elixir release."""

FRONTEND_COMMANDS = [
    "npm run build",
]

BACKEND_COMMANDS = [
    "MIX_ENV=prod mix release --overwrite",
]
