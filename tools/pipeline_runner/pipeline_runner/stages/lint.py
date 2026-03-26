"""Lint stage: code formatting and style checks."""

BACKEND_COMMANDS = [
    "mix format --check-formatted",
]

FRONTEND_COMMANDS = [
    "npx eslint src --ext .ts,.vue",
]
