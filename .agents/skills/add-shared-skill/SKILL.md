---
name: add-shared-skill
description: Install a shared Chiron, Vixxo, or approved third-party skill into a named repo using native npx skills add. Use when Derek says add a skill to a repo, install shared skill, or sync a skill into another project.
---

# Add Shared Skill

Thin wrapper around the native skills CLI. Not a custom sync engine.

## Trigger

Derek asks to:

- Add skill X to repo Y
- Install a shared skill into a project
- Put a marketplace / Chiron / Vixxo skill into another repo for cloud agents

## Steps

1. Resolve the target repo under `~/Public/<name>` (or an absolute path Derek gives). Fail if it is not a git working tree.
2. Resolve the skill source:
   - Chiron shared: `dneighbors/chiron-agent-skills`
   - Vixxo: `vixxo-copilot/agent-skills` (or a skill path under it)
   - Third-party: the GitHub `owner/repo` Derek names or that appears in the skill inventory
3. From the target repo root, run:

```bash
npx skills add <source> --skill <skill-name> --copy -y
```

4. Verify `.agents/skills/<skill-name>/SKILL.md` exists as a real file (not a broken external symlink).
5. Confirm `skills-lock.json` was created or updated.
6. Show `git status` / diff for the skill files.
7. Remind Derek: commit `.agents/skills/` and `skills-lock.json` if Cloud Agents or Automations need the skill. Do not commit unless he explicitly asks.
8. Never edit gtd-life `.cursor/mcp-sync-state.json`, `.cursor/mcp.json.bak-*`, or Vixxo-managed MCP keys.

## List available Chiron skills

```bash
npx skills add dneighbors/chiron-agent-skills --list
```

## Global install (local IDE only)

```bash
npx skills add dneighbors/chiron-agent-skills --skill <skill-name> -g -y
```

Global installs help interactive Cursor/Claude on this Mac. They do not help Cloud Agents. Use project `--copy` for cloud.
