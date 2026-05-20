# ADR-026: Template/fork branch separation strategy

## Status

Accepted — 2026-05-21

## Context

Phase A (Roadmap #22, shipped 2026-05-20) emptied `CLAUDE.md` of volatile state and relocated the Roadmap index to `.claude/ROADMAP.md`. The remaining problem: every fork user who clicks "Use this template" on GitHub still inherits 38 Specs, 46 ADRs, 2 PRDs, 15 template-internal scripts under `.claude/meta/scripts/`, and 8 template-internal CI workflows. That payload is noise — sometimes hostile noise — for downstream projects, and it conflates "template development history" with "fork starter kit." A single-branch repo cannot serve both audiences. GitHub's template-repo feature copies only the **default branch** into the new repository (docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-template-repository), which gives us a clean separation primitive if we cooperate with it.

## Decision

Adopt a two-branch model. `main` becomes the **fork-clean payload**: only the files a downstream project needs on day one (templates, agents, skills, hooks, settings, README, CHANGELOG, CLAUDE.md skeleton, and the 4 fork-reusable CI workflows: ci-base.yml, security.yml, coverage-gate.yml, workaround-check.yml). `develop` becomes the **template-development branch** carrying Specs, ADRs, PRDs, `.claude/meta/`, `.claude/ROADMAP.md`, and the 8 template-internal CI workflows (bilingual-parity-check, dangling-ref-check, docs-freshness, ecc-delegation-consistency-check, learn-invariants, research-tier-auth-check, roadmap-drift-check, skill-invariants). `main` is set as the GitHub default branch so the "Use this template" button copies only the payload. Template-development work happens on `develop` (or feature branches off `develop`) and lands in `main` via a gated `develop → main` merge whose diff is constrained by a payload allowlist enforced by a new `payload-manifest-check.yml` CI workflow on `develop`. That workflow fails any PR whose `base` is `main` and whose diff touches a path matching the template-internal glob set.

## Consequences

### Positive

- "Use this template" produces a clean repo with no template-internal noise.
- The payload-manifest workflow is the single mechanical source of truth for fork-visible scope; drift cannot land silently.
- Template-dev iteration (new ADRs, Specs, meta scripts) no longer pollutes fork history.

### Negative

- Two long-lived branches to maintain; some changes (e.g., a new agent that also needs a Spec) require coordinated commits on both sides of the merge.
- Existing forks created from pre-#23 `main` carry the old payload; they must opt into the cleanup manually.

### Neutral

- CI matrix doubles for paths that exist on both branches (agents, skills, hooks).
- Rollback path: revert `main` to the pre-cutover SHA (tagged `pre-phase-b`) and reset the default branch — `develop` is unaffected.

## Alternatives considered

| Alternative | Pros | Cons | Why not chosen |
|---|---|---|---|
| Amend ADR-014 with a "fork-clean" clause | One fewer ADR | ADR-014 keys *Roadmap index location*, not branch topology — orthogonal contract | Fails all 3 triad axes |
| `.gitattributes export-ignore` only | No branch split needed | Only affects `git archive`, not template-button clones | Wrong primitive — GitHub template clone is a branch copy |
| Separate template-dev repo | Hardest isolation | Loses PR cross-reference, doubles infra | Cost exceeds benefit at current scale |

## References

- `.claude/meta/adr/014-roadmap-index-single-entry-point.md` — Roadmap index residency (precedent for relocating template-internal state)
- `.claude/meta/adr/018-bilingual-parity-detector.md` — CI-enforced structural invariant (precedent for the payload-manifest gate)
- GitHub Docs: docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-template-repository (default-branch copy semantics)
- GitHub Docs: docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/managing-a-branch-protection-rule (branch protection for multi-branch model)
- `specs/22-claude-md-invariant-refactor.md` — Phase A (precedent for the invariant-only refactor that enables this branch split)
- `specs/23-template-fork-branch-separation.md` — Spec authoring this milestone (drafted in parallel by product-manager)
- Roadmap row: #23
