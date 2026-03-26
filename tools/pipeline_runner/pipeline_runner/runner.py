"""Main pipeline orchestrator."""

import subprocess
import time
from dataclasses import dataclass

from rich.console import Console
from rich.panel import Panel

from pipeline_runner.config import STAGES, StageConfig

console = Console()


@dataclass
class StageResult:
    """Result of running a single pipeline stage."""

    name: str
    success: bool
    output: str
    duration_ms: int


def run_stage(config: StageConfig) -> StageResult:
    """Run a single pipeline stage and return the result."""
    console.print(f"\n[bold cyan]Running stage: {config.name}[/bold cyan]")

    combined_output: list[str] = []
    total_ms = 0
    all_success = True

    for command in config.commands:
        console.print(f"  [dim]$ {command}[/dim]")
        start = time.monotonic()

        try:
            result = subprocess.run(
                command,
                shell=True,
                capture_output=True,
                text=True,
                cwd=config.workdir,
                timeout=300,
            )

            elapsed_ms = int((time.monotonic() - start) * 1000)
            total_ms += elapsed_ms
            output = result.stdout + result.stderr
            combined_output.append(output)

            if result.returncode != 0:
                all_success = False
                console.print(f"  [red]Command failed (exit {result.returncode})[/red]")
                if output.strip():
                    console.print(Panel(output.strip()[:2000], title="Error Output", border_style="red"))
                break
            else:
                console.print(f"  [green]Done[/green] ({elapsed_ms}ms)")

        except subprocess.TimeoutExpired:
            elapsed_ms = int((time.monotonic() - start) * 1000)
            total_ms += elapsed_ms
            combined_output.append("TIMEOUT: Command exceeded 300s limit")
            all_success = False
            console.print("  [red]TIMEOUT[/red]")
            break

        except Exception as exc:
            elapsed_ms = int((time.monotonic() - start) * 1000)
            total_ms += elapsed_ms
            combined_output.append(f"ERROR: {exc}")
            all_success = False
            console.print(f"  [red]ERROR: {exc}[/red]")
            break

    return StageResult(
        name=config.name,
        success=all_success,
        output="\n".join(combined_output),
        duration_ms=total_ms,
    )


def run_pipeline(
    stages: list[str] | None = None,
    fail_fast: bool = True,
) -> list[StageResult]:
    """Run the full pipeline or a subset of stages.

    Args:
        stages: List of stage names to run. If None, runs all stages.
        fail_fast: Stop on first failure if True.

    Returns:
        List of StageResult for each stage that was run.
    """
    stage_configs = STAGES

    if stages:
        unknown = set(stages) - {s.name for s in stage_configs}
        if unknown:
            console.print(f"[red]Unknown stages: {', '.join(unknown)}[/red]")
            console.print(f"[dim]Available: {', '.join(s.name for s in stage_configs)}[/dim]")
            return []
        stage_configs = [s for s in stage_configs if s.name in stages]

    results: list[StageResult] = []

    for config in stage_configs:
        result = run_stage(config)
        results.append(result)

        if not result.success and fail_fast:
            console.print(f"\n[bold red]Pipeline stopped: {config.name} failed[/bold red]")
            break

    return results
