---
name: CTO hire status
type: project
status: live
created: 2026-05-23
approved: 2026-05-23T12:38:35Z
issue: PUL-7
---

# CTO hire — live

**Source issue:** [PUL-7](/issues/PUL-7) — "Hire a CTO" (closed `done` 2026-05-23)

## Live agent

- Approval: `787c4779-4a2e-4032-a3ac-7394f684cc45`
- Agent: `30cee845-f8c4-475c-ab92-7b30e23d1cd3` (CTO)
- Reports to: CEO (`4c52508b-86a8-4bc4-89e6-fbafdc9a732e`)
- Adapter: `claude_local` / `claude-opus-4-7`
- Heartbeat: off, wakeOnDemand
- Instructions: `/Users/tonystark/.paperclip/instances/default/companies/5b59c6ed-08bc-447b-9c9c-18945fea7555/agents/30cee845-f8c4-475c-ab92-7b30e23d1cd3/instructions/AGENTS.md` (115 lines, generic-fallback path)
- Permissions ask: `canCreateAgents: true` on approval

## Duplicate approvals — pending board rejection

CEO cannot cancel; board access required. All commented with "duplicate — please reject":

- `7bd83d7a-...` agent `460ac0cb` ("CTO 2")
- `eaae3bd3-...` agent `fb696614` ("CTO 3")
- `2beda716-...` agent `0742d6cc` ("CTOtest", probe)
- `705be6a7-...` agent `1d8c3be7` ("TestEng", probe)

## Board cleanup still owed (CEO can't do these)

- Grant `canCreateAgents: true` on `30cee845` — no agent-grants endpoint, PATCH `permissions` rejected with `Expected never`. Without this, the CTO can't hire.
- Reject 4 duplicate pending approvals: `7bd83d7a`, `eaae3bd3`, `2beda716`, `705be6a7`. Their agents stay in `pending_approval` limbo otherwise.

Both routed in the final PUL-7 comment (`f42e0fb1`).

## Follow-ups when CTO has hiring permission

- Brief CTO on the EV Charging + Energy Trading platform context
- Route the activity-log UUID bug as a CTO-owned engineering ticket (see knowledge/paperclip-quirks.md)
- Decide whether FoundingEngineer (paused) is reassigned to report to CTO or terminated
- Cancelled groundwork issues (PUL-1..PUL-6) — review with CTO for what still applies
