# Claude Code Failure Mode Taxonomy

16 documented patterns where Claude Code's agentic runtime misreports execution state. Each pattern was observed across 140+ sessions on a 2-million-line C++ codebase and validated against 130+ independent GitHub issues.

Meta-issue: [anthropics/claude-code#32650](https://github.com/anthropics/claude-code/issues/32650)

## Phase 1: Reading

**1. Rules Ignored** — Claude reads CLAUDE.md, acknowledges the rules, quotes them back accurately, then violates them in the same session.
- Filed: [#32290](https://github.com/anthropics/claude-code/issues/32290)
- Community: [#2544](https://github.com/anthropics/claude-code/issues/2544) (38 thumbs-up), 20+ independent reports

**2. Context Amnesia** — Constraints extracted correctly at message 1 are silently dropped by message 30+. Column name `npcflag` verified early in session reverts to training-data `npcflags` later.
- Filed: [#32659](https://github.com/anthropics/claude-code/issues/32659)
- Community: [#6976](https://github.com/anthropics/claude-code/issues/6976) (52 thumbs-up, 90 comments)
- Mitigation: [claude-code-context-injector](https://github.com/VoxCore84/claude-code-context-injector), [claude-code-compaction-keeper](https://github.com/VoxCore84/claude-code-compaction-keeper)

## Phase 2: Reasoning

**3. Memory Assert** — States facts about database schemas from "memory" without running DESCRIBE. Assumed `gameobject_template` has 32 Data columns (actual: 35).
- Filed: [#32294](https://github.com/anthropics/claude-code/issues/32294)

## Phase 3: Generation

**4. Incorrect Artifacts** — Generates INSERT with 32 values for a 49-column table. Reports "SQL written successfully." MySQL returns ERROR 1136.
- Filed: [#32289](https://github.com/anthropics/claude-code/issues/32289)

**5. Apology Loop** — User catches mistake. Claude apologizes, explains why it was wrong (accurately), describes the fix (correctly), then reports the fix without executing it OR regenerates the same broken code.
- Filed: [#32656](https://github.com/anthropics/claude-code/issues/32656)
- Community: [#3382](https://github.com/anthropics/claude-code/issues/3382) (874 thumbs-up, 179 comments) — most-upvoted behavioral bug in the repo

## Phase 4: Execution

**6. Phantom Execution** — The anchor issue. Claude reports "All 7 files applied cleanly — zero errors." DBErrors.log was never read (proved by tool call history). One SQL file was never applied. When confronted, Claude found and applied it — proving it knew the file existed.
- Filed: [#32281](https://github.com/anthropics/claude-code/issues/32281)
- This is the most falsifiable claim in the set: compare the completion report against the tool call log.

**7. Blind Edits** — Edit tool called, result never read back. Target string not found = silent fail. Wrong occurrence matched = wrong location modified.
- Filed: [#32658](https://github.com/anthropics/claude-code/issues/32658)
- Mitigation: [claude-code-edit-verifier](https://github.com/VoxCore84/claude-code-edit-verifier)

**8. Ignores Stderr** — SQL outputs `Query OK, 0 rows affected` followed by `3 warnings`. Claude reports "Applied cleanly." Exit code 0 is treated as categorical success regardless of output content.
- Filed: [#32657](https://github.com/anthropics/claude-code/issues/32657)

## Phase 5: Reporting

**9. Tautological QA** — After copying 60K rows, ran EXISTS checking if source rows exist in target — returns 100% by definition. A valid verification query must be capable of returning failure. If it can only succeed, it's theater.
- Filed: [#32291](https://github.com/anthropics/claude-code/issues/32291)

**10. Unverified Summaries** — Post-import summary: 9 rows of specific deltas. Only 1 of 9 independently verified. The other 8 copied from the import document without checking.
- Filed: [#32296](https://github.com/anthropics/claude-code/issues/32296)

**11. Never Surfaces Mistakes** — After a 7-file import + QA, I needed 5 sequential probing questions to surface 4 distinct mistakes. Self-reported completion: 100%. Actual: ~67%.
- Filed: [#32301](https://github.com/anthropics/claude-code/issues/32301)

## Phase 6: Recovery

**12. Skips Steps** — Silently skips documented procedure steps without asking.
- Filed: [#32295](https://github.com/anthropics/claude-code/issues/32295)

**13. No Verification Gates** — No per-step verification between multi-step procedures. Batches verification to the end (or skips it entirely).
- Filed: [#32293](https://github.com/anthropics/claude-code/issues/32293)

## Supplemental: Infrastructure & Cross-Cutting

**14. LSP Integration Failures** — Language server diagnostics ignored or misinterpreted.
- Community: [#13952](https://github.com/anthropics/claude-code/issues/13952) (102 thumbs-up)

**15. Multi-Tab Token Waste** — Duplicate work across concurrent sessions with no cross-tab awareness, burning API tokens on redundant operations.
- Filed: [#32660](https://github.com/anthropics/claude-code/issues/32660)

**16. Model Downgrade Without Notification** — Backend model silently changes mid-session with no user notification, altering behavior without explanation.
- Filed: [#32661](https://github.com/anthropics/claude-code/issues/32661)

## Root Causes

1. **Context Window Attention Competition** — Instructions compete with task tokens for finite attention. Compliance degrades as context fills.
2. **KV Cache Stale Context** — [#29230](https://github.com/anthropics/claude-code/issues/29230): improved cache hit rates increased hits on stale prefix entries without invalidation.
3. **Training Signal Mismatch** — RLHF rewards at the response level, not the claim level. Confident summaries score higher than honest partial reports.
4. **Confidence Calibration Failure** — Uniform confidence regardless of evidence level.
5. **Missing Execution Boundary** — No policy layer between the model's stated intent and actual tool execution.

## Cross-Platform Validation

The same failure modes appear in Cursor, VS Code Copilot, Continue, Zed, and Cline when using Claude as the backend. These are model-level behaviors, not CLI-level bugs.

Four frontier AI systems (ChatGPT, Grok, Gemini, Claude) independently reviewed the full evidence package and converged on the same root cause: there is no execution boundary between what the model claims and what actually happened.
