---
name: bmad-swarm
description: Full autonomous BMAD development swarm — creates story, implements with parallel subagents, reviews, fixes, and ships a PR. Supports single story, multi-story, or full epic mode. Use when the user invokes /bmad-swarm or asks to swarm a story/epic.
---

# BMAD Swarm — Autonomous Development Pipeline

You are orchestrating a FULLY AUTONOMOUS development pipeline using the BMAD Method v6.
Your job: take a story from backlog to merged PR with ZERO user interaction.

**Target:** $ARGUMENTS

When invoked as a skill, the user's arguments after `/bmad-swarm` are `$ARGUMENTS` (same as the former Claude command).


## Project Paths (resolve from config)

Read `_bmad/bmm/config.yaml` first. Then set:
- PROJECT_ROOT = the project root (where _bmad/ lives)
- PLANNING = `_bmad-output/planning-artifacts`
- IMPL = `_bmad-output/implementation-artifacts`
- SPRINT_STATUS = `IMPL/sprint-status.yaml`

---

## PHASE 0: Target Resolution

Read SPRINT_STATUS fully. Then determine mode:

### Mode A — Single Story
If $ARGUMENTS is a story number like "0-1" or "2.3":
- Parse EPIC_NUM and STORY_NUM
- Look up full STORY_KEY in sprint status
- Set MODE = "single"

### Mode B — Next Story
If $ARGUMENTS is "next" or empty:
- Find FIRST story in sprint status with status "backlog" (scan top to bottom)
- Set EPIC_NUM, STORY_NUM, STORY_KEY from that entry
- Set MODE = "single"

### Mode C — Full Epic
If $ARGUMENTS matches "epic-N", "epic N", or just "epic 0", "epic-0":
- Parse EPIC_NUM from the argument
- Set MODE = "epic"
- Scan sprint status for ALL stories in this epic (keys matching `{EPIC_NUM}-*-*`)
- Build an ordered list of stories and their statuses
- Find the FIRST story in this epic that is NOT "done" and NOT "review"
  - If status is "backlog" → this is the target (needs create + dev + review)
  - If status is "ready-for-dev" → this is the target (needs dev + review, skip Phase 1)
  - If status is "in-progress" → this is the target (needs dev continuation + review)
- If ALL stories in the epic are "done":
  - Output: "All stories in epic {EPIC_NUM} are complete."
  - Output: `<promise>DONE</promise>`
  - STOP — nothing to do
- Set STORY_KEY to the selected story

**Display status summary before proceeding:**
```
BMAD Swarm — Epic {EPIC_NUM} Status
  {story-key}: done
  {story-key}: done
  {story-key}: backlog  ← targeting this one
  {story-key}: backlog
  {story-key}: backlog
```

### Mode D — Multiple Stories
If $ARGUMENTS starts with "stories" (e.g., "stories 1-3, 1-8, 1-9, 1-12"):
- Strip "stories" prefix, split remaining by comma, trim whitespace
- Each item is a short story ref like "1-3" — resolve each to its full STORY_KEY by matching `{ref}-*` in sprint status
- Validate ALL story refs resolve to valid keys; if any fail, report and STOP
- Determine EPIC_NUM from the first story; if stories span multiple epics, use the first epic's number for branch naming
- Build STORY_QUEUE = ordered list of resolved story keys
- Set MODE = "multi"
- Set STORY_KEY to the first entry in STORY_QUEUE

**Display story queue before proceeding:**
```
BMAD Swarm — Multi-Story Mode
  Queue:
    1-3-booking-intent: backlog
    1-8-seo-schema: backlog
    1-9-analytics: ready-for-dev
    1-12-sitemap: backlog
  Branch: stories/{EPIC_NUM}-batch
```

Store EPIC_NUM, STORY_NUM, STORY_KEY, STORY_QUEUE, MODE for all subsequent phases.

---

## PHASE 0.5: Create Branch (and optionally Worktree)

**Create the feature branch BEFORE any work begins.** This ensures all changes happen on the feature branch, not main.

### Flag: `--use-worktree`

If `$ARGUMENTS` contains `--use-worktree` (strip it from $ARGUMENTS before Phase 0 parsing):
- After determining the branch name below, create BOTH the branch and a git worktree
- Worktree path: `../worktrees/{BRANCH_NAME}` (relative to PROJECT_ROOT)
- Command: `git worktree add ../worktrees/{BRANCH_NAME} -b {BRANCH_NAME}`
  - If the branch already exists: `git worktree add ../worktrees/{BRANCH_NAME} {BRANCH_NAME}`
- Set WORKTREE_PATH to the absolute path of the created worktree
- All subsequent phases must work within WORKTREE_PATH (use absolute paths or cd into it)
- Log: "Created worktree at {WORKTREE_PATH} on branch {BRANCH_NAME}"

### Branch naming

Determine the branch name based on mode:

- **MODE = "single"**: BRANCH_NAME = `story/{STORY_KEY}`
- **MODE = "multi"**: BRANCH_NAME = `stories/{EPIC_NUM}-batch` (e.g., `stories/1-batch`)
- **MODE = "epic"**: BRANCH_NAME = `epic-{EPIC_NUM}/{epic-slug}`

### Without `--use-worktree` (default)

1. Create and switch to the branch: `git checkout -b {BRANCH_NAME}`
2. If branch already exists: `git checkout {BRANCH_NAME}` (switch to existing branch)
3. If the checkout also fails, report the error and STOP
4. Confirm you are on the correct branch before proceeding
5. **CRITICAL — Sync with main:** If the branch already existed (step 2), it may be stale. Run:
   ```
   git fetch origin main
   git merge origin/main --no-edit
   ```
   - If the merge has conflicts, resolve them, run the test suite to verify, then commit the merge before proceeding
   - If the merge is clean, proceed
   - This prevents building an entire epic on a stale branch and discovering conflicts only at PR time
   - Log: "Synced branch with main (N commits merged)" or "Branch already up to date with main"

### With `--use-worktree`

1. Create worktree + branch as described above
2. If worktree creation fails because the branch already exists, try without `-b`
3. If worktree already exists at that path, verify it's on the correct branch and reuse it
4. If all attempts fail, report the error and STOP
5. Confirm the worktree exists and is on the correct branch before proceeding
6. **CRITICAL — Sync with main:** If reusing an existing branch (step 2 or 3), merge main:
   ```
   git fetch origin main
   git merge origin/main --no-edit
   ```
   Resolve any conflicts before proceeding. This prevents building on a stale branch.

---

## PHASE 1: Create Story (Sequential — Task Agent)

**Skip this phase if story status is already "ready-for-dev" or "in-progress".**

Launch ONE Task agent (subagent_type: "general-purpose") with this mission:

**Prompt for the agent:**
> Read the autonomous story creator instructions at `.agents/skills/bmad-swarm/agents/bmad-story-creator.md` (or this skill's `agents/bmad-story-creator.md`).
> Execute them with:
> - STORY_KEY = {resolved story key}
> - EPIC_NUM = {epic num}
> - STORY_NUM = {story num}
> - PROJECT_ROOT = {project root}
>
> This is autonomous — no user interaction. Run in yolo mode.
> Return the story file path and the list of task groups that can be parallelized.

**Wait for completion.** Extract from the result:
- STORY_PATH = path to created story file
- PARALLEL_TASK_GROUPS = groups of tasks that can run in parallel

---

## PHASE 2: Dev Story (Parallel Subagent Swarm)

Read the created story file at STORY_PATH. Analyze the Tasks/Subtasks section.

**Strategy for parallelization:**
- Group tasks that are INDEPENDENT (no shared file dependencies, no ordering requirements)
- Tasks within the same acceptance criterion that modify different files CAN be parallel
- Tasks that depend on output from other tasks MUST be sequential
- When in doubt, keep tasks sequential within their group

**Launch parallel Task agents** (subagent_type: "general-purpose") — one per independent task group:

For each task group, the prompt is:
> Read the autonomous dev agent instructions at `.agents/skills/bmad-swarm/agents/bmad-story-dev.md` (or this skill's `agents/bmad-story-dev.md`).
> Execute them with:
> - STORY_PATH = {story file path}
> - TASK_GROUP = "{description of tasks in this group}"
> - PROJECT_ROOT = {project root}
>
> Implement ONLY the tasks in your assigned group. Do NOT touch tasks outside your group.
> Return your structured results report.

**If tasks cannot be parallelized** (too interdependent), launch a single agent with TASK_GROUP = "ALL".

**Wait for ALL dev agents to complete.** Collect results from each.

**After all dev agents finish:**
1. Read the story file to verify all tasks are marked [x]
2. If any tasks remain unchecked, launch additional agents to complete them
3. Run the full test suite to verify no conflicts between parallel work
4. If tests fail, fix integration issues in the main context
5. Update sprint-status.yaml: story status = "review"

---

## PHASE 3: Review + Test (Parallel Swarm)

Launch TWO Task agents in parallel (both subagent_type: "general-purpose"):

**Agent 1 — Code Review:**
> Read the adversarial code reviewer instructions at `.agents/skills/bmad-swarm/agents/bmad-code-reviewer.md` (or this skill's `agents/bmad-code-reviewer.md`).
> Execute them with:
> - STORY_PATH = {story file path}
> - PROJECT_ROOT = {project root}
>
> Return your structured REVIEW_SUMMARY and FINDINGS.

**Agent 2 — Test Runner:**
> Read the test runner instructions at `.agents/skills/bmad-swarm/agents/bmad-test-runner.md` (or this skill's `agents/bmad-test-runner.md`).
> Execute them with:
> - STORY_PATH = {story file path}
> - PROJECT_ROOT = {project root}
>
> Return your structured TEST_RESULTS.

**Wait for BOTH to complete.** Collect findings from each.

---

## PHASE 4: Apply ALL Fixes (Sequential — Main Context)

Consolidate findings from code review and test runner:

1. Parse the code review FINDINGS list
2. Parse the test runner FAILURES and LINT_RESULTS
3. Deduplicate (same file/line from different agents)
4. Sort by severity: CRITICAL > HIGH > MEDIUM > LOW

**Apply ALL fixes:**
- For each finding, implement the fix described
- Run tests after each batch of related fixes
- Update the story file:
  - Add "Senior Developer Review (AI)" section with findings
  - Add "Review Follow-ups (AI)" to Tasks/Subtasks with [x] for each fix applied
  - Update File List with any new/modified files
  - Update Change Log with review fix summary
  - Update Dev Agent Record with review resolution notes

**After all fixes applied:**
- Run full test suite one final time
- Verify ALL tests pass
- If any test still fails, debug and fix in main context
- Update story status to "done"
- Update sprint-status.yaml: story status = "done"

---

## PHASE 5: Commit (Sequential)

**The branch was already created in Phase 0.5. You should already be on it.**

Verify you are on the correct feature branch before committing:
- If `--use-worktree` was used: ensure you are working within WORKTREE_PATH
- Single mode: branch should be `story/{STORY_KEY}`
- Multi mode: branch should be `stories/{EPIC_NUM}-batch`
- Epic mode: branch should be `epic-{EPIC_NUM}/{epic-slug}`

If you are NOT on the correct branch, switch to it now before staging files.

### MODE = "single" (one story)
1. Stage all changed files (be specific — list files, don't use `git add -A`)
2. Create a commit with message format:
   ```
   feat(epic-{EPIC_NUM}): {story title} (Story {STORY_KEY})

   - [summary of what was implemented]
   - [key technical decisions]
   - Code review findings addressed ({N} fixes applied)

   Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
   ```
3. Push branch and create PR using `gh pr create`:
   - Title: `feat(epic-{EPIC_NUM}): {story title}`
   - Body: include story summary, ACs satisfied, review fixes applied, test results

### MODE = "multi" (multiple stories)
1. Stage all changed files (be specific — list files, don't use `git add -A`)
2. Create a commit with message format:
   ```
   feat(epic-{EPIC_NUM}): {story title} (Story {STORY_KEY})

   - [summary of what was implemented]
   - [key technical decisions]
   - Code review findings addressed ({N} fixes applied)

   Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
   ```
3. Do NOT push or create a PR yet — continue to Phase 6 for the next story in the queue
4. Push and create PR only when ALL stories in STORY_QUEUE are done (in Phase 6)

### MODE = "epic" (full epic)
1. Stage all changed files (be specific — list files, don't use `git add -A`)
2. Create a commit with message format:
   ```
   feat(epic-{EPIC_NUM}): {story title} (Story {STORY_KEY})

   - [summary of what was implemented]
   - [key technical decisions]
   - Code review findings addressed ({N} fixes applied)

   Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
   ```
3. Do NOT push or create a PR yet — continue to Phase 6 for the next story
4. Push and create PR only when ALL stories in the epic are done (in Phase 6)

---

## PHASE 6: Loop or Finish

**If MODE = "single":**
- This story is done. Output: `<promise>DONE</promise>`

**If MODE = "multi":**
- Remove the just-completed story from STORY_QUEUE
- Display updated queue progress
- If STORY_QUEUE is empty:
  - Push the branch and create a single PR using `gh pr create`:
    - Title: `feat: {N} stories ({short story refs joined by ", "})`
    - Body: include summary of ALL stories completed, total test results, review fixes
  - Output: "All queued stories are complete!"
  - Output: `<promise>DONE</promise>`
- If STORY_QUEUE has remaining stories:
  - Output: "Story {STORY_KEY} complete. {remaining} stories left in queue. Continuing..."
  - Set STORY_KEY to the next story in STORY_QUEUE
  - Parse EPIC_NUM and STORY_NUM from the new STORY_KEY
  - **LOOP BACK TO PHASE 1** (or skip to Phase 2 if story is already "ready-for-dev")

**If MODE = "epic":**
- Re-read SPRINT_STATUS to get fresh state
- Count remaining stories in epic {EPIC_NUM} that are NOT "done"
- Display updated epic progress table
- If remaining == 0:
  - Push the epic branch and create a single PR using `gh pr create`:
    - Title: `feat(epic-{EPIC_NUM}): {epic title}`
    - Body: include summary of ALL stories completed, total test results, review fixes
  - Output: "All stories in epic {EPIC_NUM} are complete!"
  - Output: `<promise>DONE</promise>`
- If remaining > 0:
  - Output: "Story {STORY_KEY} complete. {remaining} stories left in epic {EPIC_NUM}. Continuing..."
  - **LOOP BACK TO PHASE 0** — resolve the next story in this epic and repeat Phases 1-6
  - The loop continues until every story in the epic is "done"

**Epic loop keeps the orchestrator lean because:**
- All heavy work happens in subagents (fresh context each)
- The main context only tracks phase orchestration
- Each story's subagents start clean — no context bleed between stories

---

## Error Recovery

- If story creation fails: report error, do NOT proceed
- If a dev agent fails on a task: retry once with a fresh agent, then report failure
- If tests fail after parallel dev: attempt fix in main context, re-run tests
- If code review finds CRITICAL issues that can't be auto-fixed: report and stop
- If git push fails: report error with details
- At any HALT: report what completed and what failed, do NOT output the promise

## Orchestration Rules

- Use TaskCreate/TaskUpdate to track progress through phases
- Launch parallel agents using multiple Task tool calls in a SINGLE message
- Subagent prompt files: check this skill's `agents/*.md` first (bundled with bmad-swarm), then `_bmad/bmm/agents/swarm/*.md` (project-level), then `~/.claude/agents/bmad-*.md` (global laptop fallback)
- ALWAYS read the agent prompt file content and include it in the Task agent's prompt
- Subagents are "general-purpose" type — they have Read, Write, Edit, Bash, Glob, Grep
- The main orchestrator (you) handles sequencing, the subagents handle execution
- Monitor subagent results and handle failures before proceeding to next phase
