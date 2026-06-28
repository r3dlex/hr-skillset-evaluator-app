#!/usr/bin/env python3
from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
REQUIRED = [
    '.ai/matrix.json', '.ai/init/repo-profile.json', '.ai/init/sdlc-path.md',
    '.ai/workflows/repo-workflow.md', '.ai/workflows/repo-workflow.json',
    '.ai/handoff/init-ai-repo-handoff.md', '.ai/traceability/graph.json',
    '.ai/traceability/index.md', '.ai/traceability/validation-report.md',
    '.ai/evals/coverage-exceptions.json', '.ai/evals/example-output-eval/evalset.json',
    '.ai/evals/example-output-eval/rubric.md', '.ai/evals/example-output-eval/judge-config.json',
    '.ai/policies/model-routing.json', '.ai/observability/conventions.md',
    '.ai/observability/audit-checklist.md', '.ai/mcp/registry.json',
    '.ai/mcp/a2a-handoff.md', '.ai/reviews/ai-failure-modes.md',
    '.memory/human-override/custom-conventions.md', '.memory/human-override/tribal-knowledge.md',
    '.memory/self-learned/error-patterns.json', '.memory/self-learned/module-complexity.json',
    'docs/architecture/adr/0001-init-ai-sdlc-v3.md',
    'docs/specifications/ACTIVE/init-ai-sdlc-v3.md', 'RULES.md', 'PLANS.md',
    'AGENTS.md', 'README.md', 'CLAUDE.md', 'GEMINI.md', 'CONTRIBUTING.md',
]

def fail(message: str) -> None:
    print(f'FAIL: {message}', file=sys.stderr)
    raise SystemExit(1)

for rel in REQUIRED:
    if not (ROOT / rel).exists():
        fail(f'missing {rel}')

for rel in ROOT.glob('.ai/**/*.json'):
    json.loads(rel.read_text())
for rel in ROOT.glob('.memory/self-learned/*.json'):
    data = json.loads(rel.read_text())
    if 'schema_version' not in data:
        fail(f'missing schema_version in {rel}')

matrix = json.loads((ROOT / '.ai/matrix.json').read_text())
if matrix.get('sync_strategy') != 'physical-copy':
    fail('matrix sync_strategy must be physical-copy')
if matrix.get('topology_type') == 'standalone':
    if matrix.get('max_allowed_depth') != 0 or matrix.get('current_depth') != 0:
        fail('standalone depth must be zero')
elif matrix.get('topology_type') == 'umbrella':
    if matrix.get('max_allowed_depth') != 3:
        fail('umbrella max_allowed_depth must be 3')
    if matrix.get('current_depth', 99) > matrix['max_allowed_depth']:
        fail('umbrella current_depth exceeds max')
    for repo in matrix.get('managed_repositories', []):
        if repo.get('depth', 99) > matrix['max_allowed_depth']:
            fail(f'managed repo exceeds depth: {repo}')
else:
    fail('invalid topology_type')

workflow = json.loads((ROOT / '.ai/workflows/repo-workflow.json').read_text())
for phase in workflow['phases']:
    if not (ROOT / phase['status_path']).exists():
        fail(f'missing phase status {phase["status_path"]}')

text_agents = (ROOT / 'AGENTS.md').read_text()
text_readme = (ROOT / 'README.md').read_text()
for link in ['.ai/workflows/repo-workflow.md', '.ai/workflows/repo-workflow.json']:
    if link not in text_agents or link not in text_readme:
        fail(f'missing workflow link {link} in AGENTS.md or README.md')

graph = json.loads((ROOT / '.ai/traceability/graph.json').read_text())
ids = {n['id'] for n in graph['nodes']}
for edge in graph['edges']:
    if edge['source'] not in ids or edge['target'] not in ids:
        fail(f'dangling graph edge {edge}')
for node in graph['nodes']:
    for backlink in node.get('backlinks', []):
        if backlink not in ids:
            fail(f'dangling backlink {backlink}')

registry = json.loads((ROOT / '.ai/mcp/registry.json').read_text())
if not registry.get('servers') or 'a2a' not in registry:
    fail('invalid mcp registry')
for server in registry['servers']:
    if server.get('status') != 'stub':
        fail('mcp server status must be stub')

review = (ROOT / '.ai/reviews/ai-failure-modes.md').read_text().lower()
for word in ['hallucinated', 'slopsquatting', 'error handling', 'looks-right']:
    if word not in review:
        fail(f'missing review keyword {word}')

print('AI-SDLC validation passed')
