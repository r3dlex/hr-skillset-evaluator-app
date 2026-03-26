import { defineConfig } from "archgate";

export default defineConfig({
  adrDir: ".archgate/adr",
  rules: [
    {
      id: "no-raw-sql",
      adr: "001-no-raw-sql.md",
      severity: "error",
      patterns: [
        {
          deny: {
            files: ["backend/lib/**/*.ex"],
            contains: ["Ecto.Adapters.SQL.query", "Ecto.Adapters.SQL.query!"],
          },
          exclude: {
            files: ["backend/priv/repo/migrations/**"],
          },
        },
      ],
    },
    {
      id: "api-json-only",
      adr: "002-api-json-only.md",
      severity: "error",
      patterns: [
        {
          deny: {
            files: ["backend/lib/skillset_evaluator_web/controllers/**/*.ex"],
            contains: [".html", "Phoenix.HTML"],
          },
        },
      ],
    },
    {
      id: "component-naming",
      adr: "003-component-naming.md",
      severity: "warning",
      patterns: [
        {
          deny: {
            files: ["frontend/src/**/index.vue"],
          },
        },
      ],
    },
    {
      id: "no-secrets",
      adr: "004-no-secrets.md",
      severity: "error",
      patterns: [
        {
          deny: {
            files: [
              "backend/lib/**/*.{ex,exs}",
              "frontend/src/**/*.{ts,vue,js}",
            ],
            matchesRegex: [
              "(?:API_KEY|SECRET_KEY|PASSWORD|TOKEN|PRIVATE_KEY)\\s*[:=]\\s*[\"'][^\"'\\s]{8,}[\"']",
            ],
          },
          exclude: {
            files: [
              "**/*_test.exs",
              "**/*.spec.ts",
              "**/*.test.ts",
              "**/.env.example",
            ],
          },
        },
      ],
    },
    {
      id: "typed-api",
      adr: "005-typed-api.md",
      severity: "error",
      patterns: [
        {
          deny: {
            files: [
              "frontend/src/components/**/*.{ts,vue}",
              "frontend/src/views/**/*.{ts,vue}",
              "frontend/src/stores/**/*.{ts,vue}",
            ],
            matchesRegex: ["\\bfetch\\(", "new XMLHttpRequest", "\\baxios\\."],
          },
          exclude: {
            files: ["frontend/src/api/**"],
          },
        },
      ],
    },
  ],
});
