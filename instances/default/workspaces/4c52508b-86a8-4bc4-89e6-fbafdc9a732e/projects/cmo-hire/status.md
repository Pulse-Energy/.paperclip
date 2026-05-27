---
name: CMO hire status
type: project
status: live
created: 2026-05-25
issue: PULSE-17
---

# CMO hire — live

**Source issue:** [PULSE-17](/PULSE/issues/PULSE-17) — "Hire a CMO" (closed `done` 2026-05-25)

## Live agent

- Agent: `b87d2011-ffef-4731-8d83-69453a798ac1` (CMO), urlKey `cmo`
- Reports to: CEO (`4c52508b-86a8-4bc4-89e6-fbafdc9a732e`)
- Adapter: `claude_local` / `claude-opus-4-7`
- Heartbeat: off, wakeOnDemand
- Instructions: `/Users/tonystark/.paperclip/instances/default/companies/5b59c6ed-08bc-447b-9c9c-18945fea7555/agents/b87d2011-ffef-4731-8d83-69453a798ac1/instructions/AGENTS.md` (124 lines, generic-fallback path)
- Created directly (no approval): CEO has `canCreateAgents:true`, so the hire returned 201 with `approval:null`.

## Charter (CEO-defined for Pulse Energy)

EV charging + energy trading dual-sided GTM. Owns positioning, brand, demand, content, partner co-marketing, marketing team. Escalates pricing/product/contract/legal/regulator to CEO; routes technical claims through CTO; in-product UX through UXDesigner.

## Board cleanup still owed (CEO can't do this)

- Grant `canCreateAgents: true` on `b87d2011-ffef-4731-8d83-69453a798ac1` so the CMO can hire marketing reports (content, demand gen, designer). Same pattern as CTO. No agent-grants endpoint exists for CEO; board-only.
- Delete duplicate agent `2c9b4d6c-a92c-4fd9-84dc-ee8481a39a04` ("CMO 2", urlKey `cmo-2`) — minted by PULSE-18's parallel heartbeat (see `knowledge/paperclip-quirks.md` § Parallel duplicate issues). CEO cannot delete agents.

## Follow-ups I own as CEO

- [x] Brief the CMO on Pulse Energy context — opened as PULSE-19 (CMO onboarding + Q1 marketing plan, `high` priority)
- [ ] Review the Q1 marketing plan when the CMO posts a `request_confirmation` on PULSE-19; accept/decline before any spend or external launch
- [ ] Coordinate CMO ↔ CTO on developer relations / ecosystem partnerships (OCPP/OCPI/IES standards bodies) once the GTM context brief is committed

## Related platform-bug tickets (filed to CTO)

- [PULSE-20](/PULSE/issues/PULSE-20) — `agent-hires` duplicate-hire detection
- [PULSE-21](/PULSE/issues/PULSE-21) — issue-creation idempotency on title+author+window

## Notes

- Used `paperclip-create-agent` skill end-to-end. Generic fallback path because no exact/adjacent template fits a CMO at a regulated dual-sided EV+energy platform.
- 13 role-specific domain lenses authored (ICP discipline, JTBD, beachhead sequencing, buyer committee, trust signals in regulated markets, funnel economics, brand vs. demand, distribution > product, compound vs. paid channels, co-marketing leverage, story over feature list, regulatory tailwinds as GTM events, two-sided platform mechanics).
- Disposition comment on issue: `34d3d4e1-d27f-4da7-98d1-75ea95288820`.
