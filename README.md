# Claude Code Guardrails

![Python 3.8+](https://img.shields.io/badge/python-3.8%2B-blue) ![License: MIT](https://img.shields.io/github/license/VoxCore84/claude-code-guardrails) ![GitHub release](https://img.shields.io/github/v/release/VoxCore84/claude-code-guardrails)

Runtime hooks that catch what Claude Code gets wrong.

## Install

```bash
curl -sL https://raw.githubusercontent.com/VoxCore84/claude-code-guardrails/master/install.sh | bash
```

That's it. Two hooks, wired and ready. Start a new Claude Code session.

Or do it manually:

```bash
# Copy hooks into your project
mkdir -p .claude/hooks
curl -sL https://raw.githubusercontent.com/VoxCore84/claude-code-guardrails/master/hooks/edit-verifier.py -o .claude/hooks/edit-verifier.py
curl -sL https://raw.githubusercontent.com/VoxCore84/claude-code-guardrails/master/hooks/sql-safety.py -o .claude/hooks/sql-safety.py

# Add to .claude/settings.local.json (create if it doesn't exist)
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

## What the hooks do

### Edit Verifier (PostToolUse)

After every `Edit` tool call, reads the file back from disk and checks:

1. The new content is present (edit actually applied)
2. The old content is gone (correct occurrence was replaced)
3. If both checks fail, **blocks** and tells Claude to re-read the file

**Real result:** Caught 2 silent failures in its first 2 days -- both wrong-occurrence replacements on a 2-million-line codebase. Without the hook, those would have been invisible corruption found sessions later.

Based on [@mvanhorn's PR #32755](https://github.com/anthropics/claude-code/pull/32755). Improvements: configurable minimum threshold, old-string-gone verification, false-alarm reduction for legitimate duplicate occurrences.

### SQL Safety Gate (PreToolUse)

Intercepts every `Bash` command and checks for destructive SQL:

- `DROP TABLE` / `DROP DATABASE`
- `TRUNCATE`
- `DELETE` without `WHERE`
- `UPDATE` without `WHERE`
- `ALTER TABLE ... DROP COLUMN`

If matched, **blocks** the command and asks the user to confirm. Safe patterns (like `DROP IF EXISTS` followed by `CREATE TABLE`) are whitelisted.

Works with mysql, psql, sqlite3, mongosh, and MCP database tools. Patterns are configurable via `config.json`.

**Why this exists:** Claude Code [ran `terraform destroy` on a production database](https://news.ycombinator.com/item?id=47278720), wiping 2.5 years of student data.

## Why hooks instead of rules

I wrote a 2,000-word CLAUDE.md behavioral contract. Detailed rules about verification, error checking, never claiming success without evidence. Claude reads it, follows it -- until the context window fills up and the rules start losing the attention competition against 100,000 words of task content.

Rules are context tokens. Hooks are code. Context tokens get ignored. Code doesn't.

> "Rules in prompts are requests. Hooks in code are laws."

## The 16 failure modes

These hooks address the most damaging patterns from a taxonomy of 16 documented failure modes across 140+ sessions. Full details with GitHub issue links and community validation:

**[TAXONOMY.md](TAXONOMY.md)** -- all 16 patterns, organized by phase

**[anthropics/claude-code#32650](https://github.com/anthropics/claude-code/issues/32650)** -- meta-issue with all sub-issues linked

## More hooks

These are the two highest-impact hooks. For the full collection:

| Hook | What it does |
|------|-------------|
| [context-injector](https://github.com/VoxCore84/claude-code-context-injector) | Re-injects critical rules when keywords match |
| [compaction-keeper](https://github.com/VoxCore84/claude-code-compaction-keeper) | Preserves session state across context compression |
| [workflow-guard](https://github.com/VoxCore84/claude-code-workflow-guard) | Fast heuristics that catch process violations |
| [windows-toasts](https://github.com/VoxCore84/claude-code-windows-toasts) | Desktop notifications when Claude needs input |
| [hook-tester](https://github.com/VoxCore84/claude-code-hook-tester) | Offline test harness for validating hooks |

## Related

- [claude-code-safety-net](https://github.com/kenryu42/claude-code-safety-net) by @kenryu42
- [Anthropic's September 2025 postmortem](https://www.anthropic.com/engineering/a-postmortem-of-three-recent-issues)

## License

MIT
