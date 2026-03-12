# Claude Code Guardrails

Runtime hooks that catch what Claude Code gets wrong.

After 140 sessions on a 2-million-line C++ codebase, I documented 16 patterns where Claude Code misreports what it actually did — claiming files were applied when they weren't, running verification queries that can only return success, guessing database schemas instead of checking them.

Prompt-based rules don't fix this. Runtime hooks do.

**[Full write-up on DEV Community →](https://dev.to/voxcore84)**

## The Problem

Claude Code writes excellent code. But the execution layer between "write this" and "I wrote it" has gaps:

- **Phantom execution** — claims a command ran when the tool log proves it didn't
- **Silent edit failures** — Edit tool matches the wrong occurrence, corrupts a different location
- **Theater verification** — runs QA queries that can only return success (e.g., checking if source rows exist after a copy)
- **Apology loops** — correctly diagnoses a bug, describes the fix, then doesn't apply it or regenerates the same broken code ([874 thumbs-up](https://github.com/anthropics/claude-code/issues/3382))

Full taxonomy of all 16 patterns: **[TAXONOMY.md](TAXONOMY.md)**

## The Hooks

Each hook is a standalone repo you can install independently. Two of them matter most:

### Edit Verifier (PostToolUse)

Reads every file back after Claude edits it. Verifies the new content is there and the old content is gone. Caught 2 real silent failures in its first 2 days — wrong-occurrence replacements that would have been invisible corruption.

**→ [claude-code-edit-verifier](https://github.com/VoxCore84/claude-code-edit-verifier)**

Based on [@mvanhorn's PR #32755](https://github.com/anthropics/claude-code/pull/32755) with three improvements: configurable threshold, old-string-gone verification, and false-alarm reduction.

### SQL Safety Gate (PreToolUse)

Intercepts destructive SQL before it executes — DROP TABLE, TRUNCATE, DELETE without WHERE, ALTER DROP COLUMN. Works with Bash commands and MCP database tools. Configurable patterns and safe overrides.

**→ [claude-code-sql-safety](https://github.com/VoxCore84/claude-code-sql-safety)**

This exists because Claude Code [ran `terraform destroy` on a production database](https://news.ycombinator.com/item?id=47278720), wiping 2.5 years of student data.

### Other Hooks

| Hook | What it does | Repo |
|------|-------------|------|
| **Context Injector** | Re-injects critical rules on every prompt when keywords match | [claude-code-context-injector](https://github.com/VoxCore84/claude-code-context-injector) |
| **Compaction Keeper** | Snapshots session state before compaction so rules survive context compression | [claude-code-compaction-keeper](https://github.com/VoxCore84/claude-code-compaction-keeper) |
| **Workflow Guard** | Fast Python heuristics that catch process violations (<50ms, zero API calls) | [claude-code-workflow-guard](https://github.com/VoxCore84/claude-code-workflow-guard) |
| **Windows Toasts** | BurntToast notifications when Claude finishes tasks or needs input | [claude-code-windows-toasts](https://github.com/VoxCore84/claude-code-windows-toasts) |
| **Hook Tester** | Universal test harness — validates all hooks offline with mock payloads | [claude-code-hook-tester](https://github.com/VoxCore84/claude-code-hook-tester) |

## Quick Start

Install the two critical hooks in under a minute:

```bash
# 1. Clone into your project's hooks directory
cd your-project/.claude/hooks/
curl -O https://raw.githubusercontent.com/VoxCore84/claude-code-edit-verifier/master/edit-verifier.py
curl -O https://raw.githubusercontent.com/VoxCore84/claude-code-sql-safety/master/sql-safety.py

# 2. Add to .claude/settings.local.json
```

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit",
        "hooks": [{"type": "command", "command": "python \"$CLAUDE_PROJECT_DIR/.claude/hooks/edit-verifier.py\""}]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [{"type": "command", "command": "python \"$CLAUDE_PROJECT_DIR/.claude/hooks/sql-safety.py\""}]
      }
    ]
  }
}
```

That's it. The edit verifier reads every file back after edits. The SQL guard blocks destructive operations before they execute.

## Background

These hooks came out of 140 documented sessions where I tracked every gap between what Claude Code claimed and what actually happened. The full taxonomy with all 16 patterns, linked GitHub issues, and community validation is in [TAXONOMY.md](TAXONOMY.md).

Meta-issue on anthropics/claude-code: **[#32650](https://github.com/anthropics/claude-code/issues/32650)**

Related community work:
- [@mvanhorn's edit verification PR](https://github.com/anthropics/claude-code/pull/32755)
- [claude-code-safety-net](https://github.com/kenryu42/claude-code-safety-net) by @kenryu42
- [Anthropic's postmortem](https://www.anthropic.com/engineering/a-postmortem-of-three-recent-issues) (September 2025)

## License

MIT — Copyright (c) 2026 VoxCore84
