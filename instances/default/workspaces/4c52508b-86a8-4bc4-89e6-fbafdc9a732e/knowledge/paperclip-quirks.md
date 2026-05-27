---
name: Paperclip server quirks
type: reference
discovered: 2026-05-23
---

# Paperclip server quirks I have hit

## `X-Paperclip-Run-Id` must be a UUID

The activity-log table types `run_id` as `uuid`. If the header is a non-UUID string (e.g. `cto-hire-1779539626`), the request returns 500 *after* the primary write has succeeded — so the action lands in the DB but the response looks like a server error. Retrying creates duplicates.

**Always use `$PAPERCLIP_RUN_ID` from the harness for issue mutations, or `uuidgen | tr A-Z a-z` for ad-hoc requests.** Never just timestamp.

Observed in: `POST /api/companies/.../agent-hires`. Likely affects every mutating endpoint that calls `logActivity`.

## Issue mutations are locked to the harness's run id

When the harness has checked out an issue, you must use `$PAPERCLIP_RUN_ID` (e.g. `7fd96f35-...`) — a fresh UUID will be rejected with 409 "Issue run ownership conflict". This includes linking approvals to an issue and posting issue comments.

## CEO cannot cancel approvals or delete agents

`DELETE /api/agents/:id` → 403 board access required. `POST /api/approvals/:id/cancel` → 404. The only path to clean up duplicate pending hires is asking the board to reject them.

## `agent-hires` auto-attaches Paperclip core skills

Submitting with no `desiredSkills` still results in the new agent receiving the standard set: `diagnose-why-work-stopped`, `paperclip`, `paperclip-converting-plans-to-tasks`, `paperclip-create-agent`, `paperclip-create-plugin`, `paperclip-dev`, `para-memory-files`, `terminal-bench-loop`. Don't list these explicitly.

## `permissions` is not set via the hire payload

`canCreateAgents` defaults to `false` on new hires. Must be granted post-approval. Mention it in the approval comment so the board grants it together with approving the hire.

## CEO with `canCreateAgents:true` bypasses board approval

When the caller has `canCreateAgents: true`, `POST /api/companies/.../agent-hires` returns `201` with `"approval": null` and the agent is created immediately as `idle`. No board gate. Use deliberately for leadership hires where the charter is clear; still ask the board for grants you cannot set (e.g. `canCreateAgents` on the new agent).

## Parallel duplicate issues produce duplicate agents

When the system creates two identical issues (same title/author/goal seconds apart) and routes both to the same agent, two heartbeats can fire in parallel. Each independently drafts a hire from any persistent file (e.g. `/tmp/cmo-agents.md`) and submits to `agent-hires` — `agent-hires` has no duplicate-role detection, so a second agent is minted. Hit on CMO hire: PULSE-17 → `b87d2011` (canonical), PULSE-18 → `2c9b4d6c` (duplicate "CMO 2").

Two product fixes filed: PULSE-20 (duplicate-hire detection at endpoint) and PULSE-21 (issue-creation idempotency on title+author+window).

Agent-side mitigation until the platform fixes land: before submitting any uniqueness-sensitive action (hires, role-defining issues), `GET /api/companies/.../agent-configurations` and check for an equivalent record by role+reportsTo created in the last few minutes. If found, do not re-submit — comment the equivalence on the wake issue and close it as a duplicate.
