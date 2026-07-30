---
name: bmad-epic-archiver
description: Archive completed BMAD epics from sprint-status.yaml and epics.md to reduce file size and LLM context. Use when the user says "archive epics", "clean up sprint status", "move done epics", or "archive completed epics".
---

# BMAD Epic Archiver

Archives fully-completed epics from active BMAD tracking files to archive files, leaving lightweight stubs behind.

## Usage

```bash
# Script lives next to this SKILL.md after install (project: .agents/skills/bmad-epic-archiver/)
SCRIPT=".agents/skills/bmad-epic-archiver/scripts/archive_epics.rb"

# Preview what would be archived (recommended first step)
ruby "$SCRIPT" /path/to/project --dry-run

# Run the archiver
ruby "$SCRIPT" /path/to/project
```

## What qualifies for archiving

An epic is archived when **all** of its stories are in terminal status (`done`, `cancelled`, or `deferred`). The epic's own status line is ignored -- an epic marked `in-progress` with all stories done IS archivable.

**Never archived:** Epic 0 (perpetual catchall).

## Files affected

| Active file | Archive file |
|---|---|
| `sprint-status.yaml` | `sprint-status-archive.yaml` |
| `epics.md` (if present) | `epics-archive.md` |

Both are in `_bmad-output/implementation-artifacts/`.

## Workflow

1. Always run with `--dry-run` first to verify which epics will be archived
2. Review the output — confirm the epic list matches expectations
3. Run without `--dry-run` to execute
4. The operation is idempotent — re-running skips already-archived epics
