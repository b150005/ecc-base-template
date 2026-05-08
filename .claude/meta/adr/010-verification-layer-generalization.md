# ADR-010: Verification Layer Generalization

## Status

Accepted — 2026-05-07

## Context

ADR-008 introduced a **research verification layer** with a strong, narrow
philosophy: a Generator (`docs-researcher`) and a Critic (`research-critic`)
operate on different tool families, and the Critic may cite **only primary
sources** — official documentation, vendor GitHub, RFCs, MDN — never
secondary sources (blogs, Q&A sites, AI summaries). This produced a
demonstrable quality gain on the one workflow it covered: external
research that informs a downstream decision.

Three of the artifacts the template produces every day still flow through a
single-author path:

1. **Implementation.** `implementer` writes the code. `code-reviewer`,
   `security-reviewer`, and the linter inspect it, but they share the same
   tool family (Read / Grep / Bash) and the same evidence base (the diff).
   No counter-implementation, no behavioral diff, no adversarial design
   probe. A subtly wrong choice can survive every reviewer because all
   reviewers see the same surface.

2. **Architecture decisions.** `architect` writes an ADR. The "Alternatives
   considered" table is filled in by the same agent that picked the
   decision. There is no structural pressure to take a rejected
   alternative seriously enough to reproduce its reasoning.

3. **Knowledge entries (Learning Mode).** `.claude/skills/learn/preamble.md`
   §11 mandates primary-source citation in every knowledge file under
   `.claude/learn/knowledge/`. Today this is enforced only by the agent
   following instructions. There is no CI gate; a secondary-source link
   silently merged once becomes a circular-reference seed for every later
   session.

ADR-008 already proved the pattern. The cost of generalizing it is real —
each verification round consumes additional model time and orchestration —
but the user has explicitly accepted that trade-off ("token consumption is
not a concern; prioritize quality and precision"). The remaining question
is **how far to generalize without overreaching**.

## Decision

Generalize ADR-008's Generator-vs-Critic, primary-source-only philosophy
into a single **Verification Layer** abstraction with three independently
default-off domains. The shared invariants:

- A Generator produces an artifact (research note, implementation, ADR
  entry, knowledge file).
- A Critic re-derives or re-checks the artifact using a **different tool
  family** and a **disjoint evidence base** wherever feasible.
- The Critic may cite **only primary sources**. Secondary sources are
  always disqualifying.
- Each domain has its own `enabled: true|false` switch. All ship default
  **off**. A single `.claude/verification.yml.example` is the source of
  truth, replacing `.claude/research-verification.yml.example`.

The three domains:

### 1. `research:` (existing — unchanged from ADR-008)

Generator = `docs-researcher`. Critic = `research-critic`. Tool families
disjoint per ADR-008. This domain is rolled into the new file with
identical semantics. ADR-008 remains the canonical reference for this
domain; ADR-010 only hosts it.

### 2. `implementation:` (new)

Generator = `implementer` (the existing agent, unchanged). Critic = a new
agent definition `adversarial-implementer`. The Critic does **not** review
the diff line-by-line (that is `code-reviewer`'s job). Instead, the Critic
implements the **same acceptance criteria** with a deliberately different
approach, runs the test suite against both, and reports the **behavioral
delta**: which test outputs differ, which edge cases each implementation
handles, which performance profile each shows. The output is a
`verification-review.md` artifact, not a code change. The PR author
decides what to do with the delta.

**Constraints on what "different approach" means.** The differences the
Critic may introduce are ranked, and the Critic must prefer the lowest
form that yields a meaningful behavioral delta:

1. **Different control flow or data structure** (default, always allowed) —
   same language, same dependency set, different algorithm or shape.
2. **Different idiom within the same library** — same API surface,
   alternative invocation pattern.
3. **Different library** — only when (a) the user has not pinned a
   specific library in the task, spec, or an existing ADR, **and** (b) the
   alternative library is already declared in the project's manifest
   (`package.json`, `pubspec.yaml`, `go.mod`, etc.) or is a standard-library
   equivalent.
4. **A library or runtime not currently in the project** — disallowed
   without explicit human approval. The Critic must instead **emit a
   verification-blocked note** describing what alternative it would have
   used and what would be needed (CLI tool, Docker image, SDK, license).
   The PR author can then approve the addition, accept the verification
   gap, or supply the environment manually.

When the user has explicitly asked for a specific library
("use Drizzle, not Prisma"), levels 3 and 4 are permanently off the table
for that task; the Critic operates at levels 1–2 and says so in the review
header.

**Environment safety.** The Critic must not install new system-level
tooling, pull Docker images, fetch binaries, or modify the project's
dependency manifest as part of verification. If a candidate alternative
needs any of those, the Critic emits the blocked-note instead. This
keeps the verification step reproducible on a learner's machine without
surprising side effects.

The Critic must cite only primary sources for any external claim
(framework docs, RFC, language spec). When the implementations agree on
all observable behavior, the Critic explicitly says so — silence is not
acceptable.

### 3. `design:` (new)

Generator = `architect`. Critic = a new agent definition
`architecture-critic`. For any ADR with status `Proposed`, the Critic
must produce **one concrete counter-proposal** that takes a rejected
alternative seriously: same constraints, different decision, full
"Consequences" section. The Critic must cite only primary sources for
any vendor- or technology-specific claim. The output is appended to the
ADR draft as a `## Counter-proposal` section under `Status: Proposed`;
the architect (and human reviewer) decide whether to revise the ADR,
adopt the counter, or document why the original choice prevails. Once
the ADR moves to `Accepted`, the counter-proposal stays as historical
record of what was seriously considered.

### Knowledge-citation enforcement (cross-cutting)

A new CI workflow extends `learn-invariants.yml` with a
**citation-discipline check**: any link in `.claude/learn/knowledge/*.md`
or in any ADR or spec file is matched against a domain blocklist
(`stackoverflow.com`, `qiita.com`, `zenn.dev`, `medium.com`, `dev.to`,
`reddit.com`, `*.blog.*`, common AI-summary domains). The blocklist lives
in `.claude/skills/research-verification/checklist.md` (single source of
truth, already present) and is read by the CI script. Matches fail the
job. The check is **default-on** because it costs nothing per run and
guards a load-bearing invariant.

## Consequences

### Positive

- ADR-008's quality gain extends to the two artifact types learners
  produce most: code and design decisions.
- Every `Proposed` ADR ships with a serious counter-proposal, so the
  "Alternatives considered" table stops being a formality.
- Implementation choices get a behavioral-delta sanity check that the
  diff-reviewing agents structurally cannot perform.
- Primary-source discipline becomes mechanically enforced on knowledge
  files — secondary sources cannot quietly accumulate into a circular
  reference.

### Negative

- Per-decision cost rises substantially. The `implementation` domain
  in particular runs the full implementation twice (once Generator,
  once Critic). User has accepted this trade-off; we still keep the
  domains default-off so non-learning forks pay nothing.
- Two new agent definitions (`adversarial-implementer`,
  `architecture-critic`) increase the surface area learners need to
  understand. ADR-009's `description` rewrite mitigates this by making
  the trigger conditions explicit.
- Counter-proposals on ADRs add length and reviewer load. We accept
  this because long-term decision quality matters more than ADR
  brevity for a learning template.
- The citation-discipline CI may produce false positives on legitimate
  links to security advisories or RFC mirrors hosted on flagged
  domains. Mitigation: an inline `<!-- cite-allow: <reason> -->`
  escape comment, used sparingly.

### Neutral

- `.claude/research-verification.yml.example` is renamed to
  `.claude/verification.yml.example`. The old filename is documented as
  superseded; existing forks that copied it keep working until they
  re-sync.
- Three domains in one config file is more discoverable than three
  separate files but slightly more rigid. We accept the rigidity.

## Alternatives considered

| Alternative | Pros | Cons | Why not chosen |
|---|---|---|---|
| Keep ADR-008 narrow; add no further domains | Lowest cost, lowest risk | Code and design — the highest-volume artifact types — never get the verification-layer benefit | The user explicitly chose quality/precision over cost |
| Single mega-Critic that reviews research, code, and design | One agent to maintain | Loses the "different tool family / disjoint evidence base" guarantee that gives ADR-008 its quality gain | Would silently regress ADR-008's invariant |
| Make `implementation` and `design` domains default-on | Maximum quality pressure | Surprises users who fork for non-learning reasons; doubles implementation cost without consent | Default-off respects the template's role; opt-in is one config line |
| Make citation-discipline default-off too | Symmetry with the other domains | Citation discipline costs essentially nothing per CI run, and the failure mode (silent secondary-source accumulation) is severe | The cost/risk asymmetry justifies the asymmetric default |
| Let the Critic pick any alternative library, installing tools as needed | Strongest behavioral-delta signal | Breaks reproducibility on a learner's machine; ignores explicit user library choices; can drag in Docker, SDKs, or license commitments without consent | Constrained to the four-level ranking above; level 4 requires human approval |

## References

- ADR-008 (Research Verification Layer) — the philosophy and protocol
  this ADR generalizes. ADR-008 remains canonical for the `research`
  domain; ADR-010 hosts the unified configuration.
- ADR-001, ADR-004 (Learning Mode, Coaching Pillar) — knowledge-citation
  enforcement protects the knowledge pillar's load-bearing invariant.
- ADR-009 (Plan-First Defaults) — landed in parallel; the `description`
  rewrite there makes the new Critic agents discoverable to the
  orchestrator.
- `.claude/skills/research-verification/checklist.md` — secondary-source
  blocklist, single source of truth shared by the CI check and the
  research domain.
