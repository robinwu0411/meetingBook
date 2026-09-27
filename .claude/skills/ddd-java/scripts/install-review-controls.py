#!/usr/bin/env python3
"""Install project review instructions and merge Git confirmation permissions."""
import json
import sys
from pathlib import Path


def install(project):
    project = Path(project).expanduser().resolve()
    if not project.is_dir():
        raise SystemExit("Project directory does not exist")
    source = Path(__file__).resolve().parent.parent / "references/review-workflow.md"
    rules = project / ".claude/rules/ddd-review.md"
    settings = project / ".claude/settings.local.json"
    for p in (project / ".claude", rules.parent, rules, settings):
        if p.is_symlink():
            raise SystemExit("Refusing symlink: " + str(p))
    content = source.read_text(encoding="utf-8")
    if rules.exists() and rules.read_text(encoding="utf-8") != content:
        raise SystemExit("Review rules already differ; review/merge them manually: " + str(rules))
    data = json.loads(settings.read_text(encoding="utf-8")) if settings.exists() else {}
    if not isinstance(data, dict):
        raise SystemExit("settings.local.json must contain an object")
    permissions = data.setdefault("permissions", {})
    if not isinstance(permissions, dict):
        raise SystemExit("permissions must contain an object")
    ask = permissions.setdefault("ask", [])
    if not isinstance(ask, list) or any(not isinstance(v, str) for v in ask):
        raise SystemExit("permissions.ask must be a string array")
    if "Bash(git *)" not in ask:
        ask.append("Bash(git *)")
    rules.parent.mkdir(parents=True, exist_ok=True)
    rules.write_text(content, encoding="utf-8")
    settings.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print("Installed review rules: " + str(rules))
    print("Merged Git confirmation rule: " + str(settings))
    print("Check /permissions in Claude Code. Text rules are not a hard stage lock.")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit("Usage: python3 install-review-controls.py PROJECT_DIR")
    install(sys.argv[1])
