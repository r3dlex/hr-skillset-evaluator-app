"""Entry point for running the pipeline via `python -m pipeline_runner`."""

import sys

import click
from rich.console import Console

from pipeline_runner.runner import run_pipeline

console = Console()


@click.command()
@click.option(
    "--stages",
    "-s",
    multiple=True,
    help="Specific stages to run (default: all). Can be repeated.",
)
@click.option(
    "--no-fail-fast",
    is_flag=True,
    default=False,
    help="Continue running stages even after a failure.",
)
def main(stages: tuple[str, ...], no_fail_fast: bool) -> None:
    """Run the CI/CD pipeline for the HR Skillset Evaluator app."""
    stage_list = list(stages) if stages else None
    fail_fast = not no_fail_fast

    console.print("\n[bold blue]HR Skillset Evaluator Pipeline[/bold blue]\n")

    results = run_pipeline(stages=stage_list, fail_fast=fail_fast)

    # Summary
    console.print("\n[bold]Pipeline Summary[/bold]")
    passed = sum(1 for r in results if r.success)
    failed = sum(1 for r in results if not r.success)
    total_ms = sum(r.duration_ms for r in results)

    for result in results:
        icon = "[green]PASS[/green]" if result.success else "[red]FAIL[/red]"
        console.print(f"  {icon} {result.name} ({result.duration_ms}ms)")

    console.print(f"\n  Total: {passed} passed, {failed} failed, {total_ms}ms\n")

    if failed > 0:
        sys.exit(1)


if __name__ == "__main__":
    main()
