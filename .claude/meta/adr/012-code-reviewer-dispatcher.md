# ADR-012: Code Reviewer as Dispatcher to ECC Language-Specific Reviewers

## Status

Accepted — 2026-05-09

## Context

The template's `code-reviewer` agent has historically performed a
generic, ecosystem-detected review — it reads `.claude/CLAUDE.md` and
the project manifest, then applies a language-agnostic checklist
(function length, file size, error handling, hardcoded secrets, etc.)
plus the template's cross-cutting checks (CLAUDE.md authoring,
upstream-workaround markers, Learning Mode contract).

ECC ships nine language-specific reviewer agents at the user level
(`~/.claude/agents/`): `typescript-reviewer`, `python-reviewer`,
`go-reviewer`, `rust-reviewer`, `cpp-reviewer`, `java-reviewer`,
`kotlin-reviewer`, `flutter-reviewer` (Dart), `csharp-reviewer`. These
agents go materially deeper on idiom, type-system footguns, async
correctness, framework-specific anti-patterns, and the parts of
language design where a generic reviewer is structurally weaker.

Per the README `## Prerequisites` section and ADR-011's framing, the
template assumes ECC is installed at the user level. A generic
project-level `code-reviewer` therefore *shadows* the user-level ECC
reviewers (Claude Code resolves project agents before user agents on
name collision), producing a strictly weaker review for any single
ecosystem than the user would have received from ECC alone.

The template's value-add cannot be language depth — that fight is
already lost to ECC's specialists. The value-add is the cross-cutting
template-internal layer: ADR conformance (ADR-006/007/008/010/011),
upstream-workaround markers (ADR-006), CLAUDE.md / agent-prompt
structure (ADR-007), verification-layer hand-offs (ADR-008/010), and
the compliance-checklist Skill trigger (ADR-011, when enabled).

This ADR records the decision made in the v3.6.0 release cycle and the
serious counter-proposal raised against it during internal review.

## Decision

Refactor `.claude/agents/code-reviewer.md` into a **meta-reviewer /
dispatcher**:

- Detect the ecosystem from project manifest files
  (`package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`,
  `CMakeLists.txt`, `pom.xml`, `build.gradle{.kts}`, `pubspec.yaml`,
  `*.csproj`).
- Delegate language-specific depth to the matching ECC reviewer.
- Layer on the template's cross-cutting checks regardless of language.
- Distinguish three delegation outcomes (succeeded / attempted-failed /
  not-attempted) and report each explicitly so a missing ECC layer is
  visible in every review report — never silently skipped.
- Fall back to the original generic checklist only when delegation is
  not attempted.
- For multi-language diffs, delegate to each matching ECC reviewer in
  parallel and consolidate.

Agent count remains at 18; only `code-reviewer`'s prompt changes.

## Consequences

### Positive

- Review depth for any single ecosystem is upgraded to ECC's
  specialist level without adding agents to the template.
- The template's cross-cutting layer (ADR conformance, workaround
  markers, claude-md-authoring, verification-layer, compliance-checklist
  triggers) becomes the unambiguous responsibility of one local agent
  — cleaner separation than mixing it into a generic reviewer.
- `code-reviewer`'s prompt becomes more honest: it documents that its
  job is *coordination plus cross-cutting checks*, not language depth.
- ECC-aware forks get a strictly better review than before. ECC-less
  forks see no regression versus the previous generic reviewer (the
  fallback path preserves the old checklist).

### Negative

- The template now has a **declared dependency on ECC** for full
  review depth. Forks that never install ECC permanently operate at
  reduced review quality, and the README must say so (it now does, via
  the `## Prerequisites` section added in this same release).
- Review output **varies by operator environment** for the
  language-specific layer. The cross-cutting layer is reproducible;
  the language-specific layer depends on which ECC version the
  operator has installed. This is a real loss of reproducibility,
  partially mitigated by the explicit verdict-line note about which
  delegation outcome occurred.
- Dispatcher logic is a new shape of agent that the orchestrator and
  human reviewers must understand. The three-case delegation outcome
  rule is documented in the agent file, but it is one more concept to
  learn.
- The contract with ECC reviewers is **unversioned**. If ECC renames
  `typescript-reviewer` or substantially changes its prompt contract,
  the dispatcher's delegation rows go stale silently. There is no CI
  check on the existence of the target agents.

### Neutral

- The previous generic reviewer logic survives as the fallback path.
  Nothing was deleted; capability was reorganized.
- This is the first template agent to hand off to ECC by name. Future
  agents may follow the pattern; this ADR establishes the precedent.

## Alternatives considered

| Alternative | Pros | Cons | Why not chosen |
|---|---|---|---|
| **A: Delete project `code-reviewer`; rely entirely on ECC's `code-reviewer`** | Maximum simplicity; no dispatcher logic | Loses the template's cross-cutting checks (ADR conformance, workaround markers, claude-md-authoring, verification-layer hand-offs, compliance-checklist triggers) — ECC's `code-reviewer` knows nothing about these and cannot replace them | Cross-cutting checks are the template's contribution; deleting the local agent throws them away |
| **B: Add language-specific reviewers under `.claude/agents/` (e.g. `typescript-reviewer.md`, `python-reviewer.md`)** | Template becomes self-contained; review reproducible regardless of ECC presence; reviewer prompts version-pinned with the template; no hidden external contract | Drifts from ECC reviewers over time without a sync mechanism; larger maintenance surface (3+ reviewer prompts initially); duplicates content for users who run both layers | See "Counter-proposal" below — this alternative was raised by `architecture-critic` during internal review and is recorded as a serious option that was not adopted for this release |
| **C: Keep `code-reviewer` generic; bake "delegate to ECC" into orchestrator hand-off logic** | No change to `code-reviewer.md` | Hides the dispatcher behavior in orchestrator prompt rather than the agent that performs it; harder to audit; the orchestrator becomes overloaded with language-specific routing | Locality of behavior is a design value here; the agent that does the work owns the prompt that describes it |
| **D: Status quo — keep the generic project-level reviewer, accept it shadows ECC** | No work | Wastes ECC's specialist depth for every review; the generic reviewer is strictly weaker for any single ecosystem; users who installed ECC don't benefit | The whole point of the template assuming ECC is to leverage it |

## Counter-proposal

During the verification-layer / design domain review of this decision
(per ADR-010, with `architecture-critic` as Critic), Alternative B —
**add language-specific reviewers directly under `.claude/agents/`** —
was produced as a counter-proposal taking a rejected alternative
seriously. The counter-proposal's argument:

1. A learning template should be self-contained. Forks may never
   install ECC; a dispatcher that silently degrades to a "generic
   fallback" when ECC is absent teaches forks that the template's
   review depth depends on a layer outside the repo — a poor lesson
   and a hidden coupling.
2. Reproducibility of reviews. The dispatcher produces different
   output depending on which ECC version is on the operator's machine,
   violating the template's reproducibility posture (pinned templates,
   ADR-driven decisions, explicit dependencies).
3. The dispatcher is a hidden contract. Delegating to "whatever ECC
   reviewer happens to be installed" depends on an unversioned,
   unpinned external surface. If ECC renames `typescript-reviewer` or
   changes its prompt contract, every fork breaks silently.
4. In-repo reviewers are forkable and auditable. A
   `.claude/agents/typescript-reviewer.md` file can be diffed,
   version-controlled, ADR-referenced, and tuned per-fork. ECC
   delegation cannot.
5. Cross-cutting checks already live locally. The marginal cost of
   also keeping idiom checks local is small compared to the cost of a
   split-brain review surface.

**Why the counter was not adopted in this release**:

- Maintenance cost is real and recurring. Maintaining nine
  language-specific reviewer prompts in a *learning template* —
  whose primary value is structure, not language coverage — turns the
  template into a competitor to ECC rather than a consumer of it. The
  counter is correct that the dispatcher's contract is unversioned;
  the response is to *strengthen the dispatcher* (CI check on the
  named ECC agents' existence at fork time, README guidance on ECC
  version pinning), not to *re-implement ECC's catalog locally*.
- The "self-contained" property the counter argues for is already
  partially abandoned: this template depends on Claude Code itself,
  on optional Skills, on Anthropic API access. Adding ECC to that
  list is a documented choice, not a hidden coupling. The README
  `## Prerequisites` section, added in this same release, makes the
  ECC dependency explicit — which addresses the "hidden coupling"
  concern directly.
- Reproducibility is a concern for *production* artifacts. This
  template produces reviews, not release artifacts; the verdict-line
  note about which delegation outcome occurred is the audit trail.
  ECC versions are operator state, not template state.

**Trigger conditions for re-evaluating this counter-proposal**:

- ECC ever ships a backwards-incompatible change to a `*-reviewer`
  agent's prompt contract.
- More than two of the named ECC reviewers disappear or are renamed
  without a documented migration path.
- A fork in active use needs a language-specific reviewer for a
  language ECC does not cover (the dispatcher fallback to the generic
  checklist remains, but the fork may want to ship its own reviewer
  prompt).
- The template's user base shifts toward operators who deliberately
  do not install ECC — at that point, the "self-contained" property
  becomes load-bearing again.

The counter-proposal stays in this ADR as historical record of what
was seriously considered, per ADR-010's design-domain protocol.

## References

- ADR-007 (CLAUDE.md Authoring Skill) — defines the cross-cutting
  authoring invariants the dispatcher's local layer enforces.
- ADR-008 (Research Verification Layer) — defines the
  verification-layer hand-off check the dispatcher's local layer
  enforces.
- ADR-010 (Verification Layer Generalization) — defines the
  design-domain Critic protocol that produced the counter-proposal
  recorded above.
- ADR-011 (Compliance Checklist Skill) — adds the compliance-checklist
  trigger row to the dispatcher's local layer.
- `.claude/agents/code-reviewer.md` — the agent prompt this ADR
  rationalizes.
- README.md `## Prerequisites` (and `README.ja.md ## 前提条件`) — the
  documented ECC-installed-at-user-level assumption this dispatcher
  relies on.
- ECC user-level reviewer catalog: `~/.claude/agents/typescript-reviewer.md`,
  `python-reviewer.md`, `go-reviewer.md`, `rust-reviewer.md`,
  `cpp-reviewer.md`, `java-reviewer.md`, `kotlin-reviewer.md`,
  `flutter-reviewer.md`, `csharp-reviewer.md` — the delegation targets.
