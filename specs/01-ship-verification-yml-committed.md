# Ship `verification.yml` as a Committed Default

## Status

Approved

**Owner:** product-manager / devops-engineer
**Target release:** template v3.7.0

## Problem

`.claude/verification.yml` ships only as `.claude/verification.yml.example`. A fork that does not manually copy and rename the file has no active verification layer: research runs without adversarial Critic review, tier mis-classifications go undetected, and wrong information can flow unchallenged into architectural decisions. The `.example` suffix signals "read this eventually" rather than "this is enforced now." Most forks never copy it because there is no prompt to do so and no visible failure when they do not. The verification layer exists and is well-designed (ADR-008, ADR-010) but is inert at fork time.

## Goals

- A freshly-forked repo has `verification.yml` present and active with `research.enabled: true` on day one, with no manual copy step required.
- The research domain (docs-researcher Generator + research-critic Critic) activates automatically on the first agent session after a fork.
- Forks that want to disable verification can still do so by editing the committed file, and the mechanism for doing so is documented inline.
- `init.sh` does not need to be modified by this milestone (the file ships committed; init.sh handles project-identity fields, not verification config).

## Non-goals

- Enabling `implementation.enabled: true` or `design.enabled: true` by default — those domains are intentionally expensive and remain opt-in (documented inline in the committed file).
- Removing `.claude/verification.yml.example` — keep it as a reference copy with all fields annotated; the committed file is the authoritative active config.
- Modifying any agent prompt (that is a downstream consequence if needed, tracked separately).

## User stories

| As a... | I want to... | So that... |
|---------|--------------|------------|
| Template adopter | Fork and immediately get research verification active | I do not discover weeks later that research ran unreviewed |
| Template maintainer | Ship a sensible verified default | Derived repos get the safety net without per-fork setup |
| Developer who wants to disable verification | Edit one clearly-documented key | I do not have to hunt for the knob |

## Acceptance criteria

- **Given** a clean fork of the template repository **when** the fork is created (no manual setup) **then** `.claude/verification.yml` exists at that path (not just `.example`) and is tracked by git.
- **Given** `.claude/verification.yml` is present **when** an agent session starts and invokes the verification-layer Skill **then** `research.enabled: true` is in effect and the Critic is engaged without any additional configuration.
- **Given** a developer wants to disable research verification **when** they set `research.enabled: false` in `.claude/verification.yml` **then** the file comment explains the effect and the change is a one-line edit.
- **Given** `.claude/verification.yml.example` exists alongside the committed file **when** a developer reads the example **then** all fields are annotated (implementation, design, citation_discipline domains included) and the example is clearly labeled as documentation-only, not the active config.
- **Given** the committed `verification.yml` **when** reviewed **then** `implementation.enabled` and `design.enabled` are `false`, consistent with their intentional opt-in cost model.

## Key interactions

1. `implementer` renames (or copies + commits) `.claude/verification.yml.example` → `.claude/verification.yml` with `research.enabled: true` and `implementation.enabled: false`, `design.enabled: false`.
2. The `.example` file is retained but clearly labeled in its header comment as "documentation reference — the active config is `verification.yml`."
3. No changes to agent prompts in this milestone; the Skill already reads the file path correctly.

## Metrics

- **Leading:** CI check on new forks verifies `verification.yml` exists (can be added as part of G4/G5 later; not a gate for this milestone).
- **Lagging:** Reduction in research-layer bypass incidents in derived repos (observable via audit if teams track it).

## Risks and open questions

- **Risk:** A downstream fork may have already committed `verification.yml.example`-based customization under a different path. Mitigation: the committed file uses the canonical path `.claude/verification.yml`; no path changes are made.
- **Risk:** `research.enabled: true` as the default increases token cost for every research-triggering agent turn. The cost was explicitly accepted when ADR-008 was ratified; this milestone makes the stated default actual.
- **Open question:** Should `citation_discipline.enabled` default to `true`? It already does in the `.example` file and the cost is near-zero per CI run. Keep it `true` in the committed file.

## Out of scope

- Changing which domains are enabled (implementation, design remain `false`).
- Any modification to agent system prompts triggered by this config change.
- Adding a CI check that validates `verification.yml` exists (that is G4/G5 territory).

## References

- ADR-008 (research verification layer)
- ADR-010 (verification-layer generalization to implementation + design domains)
- `.claude/verification.yml.example` — the source of the active config content
- Roadmap row: #01
