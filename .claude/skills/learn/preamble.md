# Learning Mode Enrichment Contract

This file is the single source of truth for the enrichment protocol that every
learning-aware agent follows when Developer Learning Mode is active. It is read at session
start by every agent that declares a `## Learning Domains` section at the top of its
prompt body, when and only when `.claude/learn/config.json` has `"enabled": true`.

The domain declaration location changed from a frontmatter key to a prompt-body section
in ADR-002; see [.claude/meta/adr/002-growth-domains-location.md](../../meta/adr/002-growth-domains-location.md)
for the rationale. The feature was renamed from "Growth Mode" to "Learning Mode" and the
output directory was relocated from `.claude/growth/notes/` to `.claude/learn/knowledge/` in ADR-003;
see [.claude/meta/adr/003-learning-mode-relocate-and-rename.md](../../meta/adr/003-learning-mode-relocate-and-rename.md)
for the rationale.

---

## 1. When This File Is Loaded

Agents read this file only when the following condition is true:

```
.claude/learn/config.json exists
AND config.json is valid JSON
AND config.enabled === true
```

When any of those conditions fails — config is absent, `enabled` is `false`, or the file
is not valid JSON — agents behave as if Learning Mode does not exist. No reads of this file.
No reads of domain files. No writes to `.claude/learn/knowledge/`. No `## Learning:` trailing
sections. The primary artifact and all agent output are byte-identical to what they would
be if Learning Mode were not installed.

This is the default-off invariant. It is the load-bearing claim of the feature. Any
deviation from byte-identical output when Learning Mode is disabled is a defect.

**Read sequence at session start (Learning Mode ON):**

1. Read `.claude/learn/config.json`. Check `enabled`.
2. If `enabled: true`, read this file (`preamble.md`) for the enrichment protocol.
3. At session start, this agent does NOT pre-load any domain file. It identifies candidate
   domains from its own `## Learning Domains` section (already present in its prompt body) so
   it knows which domains are relevant, but it reads a domain file only when a teaching
   moment actually arises for that domain.
   This keeps session-start context cost minimal and avoids loading files the agent will
   not touch.
4. Proceed with the primary task. When a teaching moment arises, follow the protocol below
   — specifically Step 2, which requires reading the domain file at that moment.

Each agent performs this sequence independently. The orchestrator does not pre-parse the
config or pre-read domain files on an agent's behalf. Each agent is responsible for its
own Learning Mode read path.

---

## 2. The Enrichment Operation Contract

Every learning-aware agent, when it has a teaching moment, follows this five-step contract
against the target domain file.

### Step 1: Identify the target domain

Map the teaching moment to a domain key the agent owns (see the `## Learning Domains`
section at the top of this agent's prompt body). Domain key definitions are in
`.claude/meta/references/domain-taxonomy.md`.

If the teaching moment spans two domains, pick the one where the concept is most
foundational. Place the primary explanation there. In the secondary domain file, write a
cross-reference link pointing to the primary entry:

```markdown
See [Repository Pattern in architecture.md](./architecture.md#repository-pattern) for
the foundational explanation. This section notes the persistence-strategy implications.
```

Do not duplicate explanatory content across domain files. Cross-references preserve
navigability without repeating material.

If no existing domain fits and the concept is genuinely new territory — not a variation
or cross-section of existing domains — propose a new domain in the diff report using this
format:

```
## Learning: knowledge diff
- PROPOSED NEW DOMAIN: <key> — <one-sentence rationale>. Confirm with /learn domain new <key>.
```

Agents never auto-create domain files without learner confirmation via `/learn domain new <key>`.

### Step 2: Read the current domain file

Read the domain file at the moment a teaching moment arises for it. If the same domain is
touched again later in the same session, reuse the already-loaded content in context
rather than re-reading from disk. This step is non-negotiable. The reasons:

- A concept section may already exist. Contributing without checking duplicates it.
- An earlier entry may state something the current session would correct. Contributing
  without checking means the correction omits the supersession marker.
- The file may have grown to a size where the agent should flag it for reorganization
  rather than adding to it blindly.

If the domain file does not exist (not yet seeded), treat it as a file with a single
empty Placeholder section. Create the file with proper front matter and the first real
section; do not create a bare file without front matter.

### Step 3: Decide the operation

One of five operations applies to every teaching moment:

**Add** — The concept has no section in this domain file. Create a new top-level H2
section (`## Concept Name`) with content at the declared level. No existing section
is touched.

**Deepen** — The concept has a section and the section is accurate but incomplete.
Append to the existing section: a new example, a caveat, an edge case, a cross-reference,
or an additional worked example. The existing content is unchanged. New content appears
below the existing content within the same section.

**Refine** — The concept has a section and the content is correct in substance but the
phrasing is imprecise, the example is weak, or a nuance is missing. Tighten the phrasing
or improve the example without changing the underlying claim. Preserve the prior phrasing
as a dated `Prior Understanding` block:

```markdown
### Prior Understanding (revised 2026-04-22)

[prior phrasing preserved here exactly]

Revised because: [one-sentence reason].
```

The revised content appears above the Prior Understanding block in the active position.

**Correct** — The concept has a section and the section states something incorrect or
outdated. Mark the prior content superseded, then write the corrected understanding below:

```markdown
> Superseded 2026-04-22: [one-sentence reason the prior claim was wrong or outdated]

[prior content preserved here exactly, indented under the blockquote]

**Corrected understanding:**

[corrected content here]
```

The superseded text is never deleted. It remains visible so the learner can see how
their understanding evolved. A session three months later that corrects the same section
again adds a second supersession marker above the first corrected version. All historical
versions accumulate in order.

**New domain** — Only after learner confirmation via `/learn domain new <key>`. See
Step 1 for the proposal format.

### Step 4: Apply the change non-destructively

Rewrite the domain file with the change integrated. The following invariants hold:

- Every heading, every code block, and every paragraph outside the change surface is
  preserved byte-for-byte. The only content that changes is the section the operation
  targets (and the front matter `last-updated` date).
- No entry is ever removed. Superseded entries stay visible with their marker.
- A `refine` operation does not delete the prior phrasing; it moves it to a dated
  Prior Understanding block below the revised text.
- A `correct` operation does not overwrite the prior claim; it marks it superseded and
  places the correction below.
- If the domain file has grown past approximately 1200 lines or 8 top-level H2 sections,
  flag this in the diff report (`FLAG: file approaching split threshold`) rather than
  reorganizing unilaterally. The technical-writer's `/learn review` command handles
  reorganization on demand.

Update the front matter `last-updated` date to today's date when writing the file.

### Step 5: Report the diff

At the end of the agent's chat response — always after the primary artifact, never
before — emit the two trailing sections:

```
## Learning: taught this session
- <concept-name>: <one-sentence summary at the declared level>

## Learning: knowledge diff
- knowledge/<domain>.md → <operation> on `## <section-heading>`: <one-sentence change summary>
```

Multiple teaching moments in the same response produce multiple bullet lines in each
section. When a new domain was proposed but not created, use the format:

```
## Learning: knowledge diff
- PROPOSED NEW DOMAIN: <key> — <rationale>. Confirm with /learn domain new <key>.
```

These sections are visible in the agent's chat response. They are not written to any
file. They are the provenance record the learner uses to audit knowledge evolution.

**These headers must be absent when Learning Mode is off.** When `config.json` is absent
or has `enabled: false`, the agent's guard branch must skip all learning steps before any
`## Learning:` text is produced.

---

## 3. Trailing Section Format (Exact)

The trailing sections use exactly these Markdown H2 headings, with a blank line before
each. No variation in capitalization or punctuation.

```
## Learning: taught this session
- <concept-name>: <one-sentence summary>

## Learning: knowledge diff
- knowledge/<domain-file>.md → <operation> on `## <section-heading>`: <change-summary>
```

Valid operation strings: `add`, `deepen`, `refine`, `correct`.

When multiple entries exist:

```
## Learning: taught this session
- Repository Pattern: a boundary object that abstracts data access so callers never see
  the database query shape.
- Error Propagation: errors cross the persistence boundary as domain error types, not
  database-specific error types.

## Learning: knowledge diff
- knowledge/architecture.md → add on `## Repository Pattern`: introduced pattern with
  first-principles explanation; includes Go worked example.
- knowledge/error-handling.md → deepen on `## Boundary Crossing`: added note on translating
  database errors at the repository boundary.
```

When a proposed new domain is included:

```
## Learning: knowledge diff
- knowledge/error-handling.md → deepen on `## Boundary Crossing`: added note.
- PROPOSED NEW DOMAIN: observability — teaching moment involved tracing patterns that do
  not fit cleanly into operational-awareness. Confirm with /learn domain new observability.
```

Detection rule: `/quiet` triggers trailer suppression only when it appears in the current
turn's user message as a **standalone whitespace-delimited token, at the top level of the
message (not inside a fenced code block), and not as a substring of a longer identifier**.
Specifically:
- Matches: a line containing only `/quiet`, or `/quiet` preceded and followed by
  whitespace.
- Does NOT match: `/quiet` inside ` ``` ` fenced code blocks; `/quiet` inside inline code
  spans `` `/quiet` ``; `/quiet` as part of a longer word like `/quieting` or `/quieter`;
  flags like `--quiet` (different token).
- The detector is case-sensitive: `/QUIET` does not trigger.

When this rule matches, these sections are entirely absent. No empty blocks. No
placeholder lines. Nothing. The knowledge files are still updated; only the chat-visible
trailer is omitted. The next user turn restores normal trailer behavior — no state is persisted.

---

## 4. Level Semantics

Levels control the angle and density of foundational context. They determine which
decisions clear the threshold for a knowledge entry and how much scaffolding accompanies
each entry. They do not set a token budget or an entry count cap. Depth follows from the
concept.

All three levels write into the same domain files. The knowledge base does not fork by level.

### junior

The agent explains from first principles. It introduces vocabulary before using it. It
names the pattern and contrasts it with the naive alternative a learner without prior
exposure would reach for. Worked examples are expanded. Prerequisite concepts are either
explained inline or cross-referenced to the domain file that covers them. The agent does
not assume the learner has encountered this concept in any context.

A typical junior-level contribution is a full section with a first-principles explanation,
an idiomatic variation block, and a trade-offs block — multiple paragraphs. That length
is intended. It is building foundational scaffolding, and scaffolding removed to hit a
length cap is scaffolding the learner will have to look up elsewhere.

### mid

The agent assumes first principles but explains the non-obvious. It focuses on what
idiomatic practitioners of this stack do that a competent engineer switching in from a
different stack would not guess. Trade-offs are named; alternatives are acknowledged
without being exhaustively compared. The agent does not re-explain concepts the mid-level
learner is expected to know; it focuses on the places where this stack or this project
diverges from what general experience would predict.

A typical mid-level contribution is one to three paragraphs. It is not terse, but it
skips the scaffolding and still explains the why.

### senior

The agent contributes only when a decision was non-default. The note names the default,
names the actual choice, and states why the choice was preferred in this context. Senior
contributions capture reasoning that would otherwise stay in the author's head. A
senior-level session that involved no non-default choices writes zero notes. That is
correct behavior, not a failure.

### Layered sections over time

When the same concept is encountered in a later session at a higher level, the agent
deepens the existing section rather than duplicating it. A senior session that encounters
the repository pattern when a junior session already explained it adds a trade-off
subsection, not a new first-principles explanation. The section accumulates layers:
foundations on top (from junior sessions), idiomatic variation in the middle (from mid
sessions), trade-off reasoning at the bottom (from senior sessions).

### Levels do not soften severity

The code-reviewer's learning content must not soften, hedge, or dilute severity labels on
findings. CRITICAL means CRITICAL at all three levels. A learning note at `junior` that
explains why a finding is CRITICAL is permitted and encouraged; that explanation does not
change the severity label. Learning content is additive to the finding, not a gloss on it.

---

## 5. Non-Destructive Edit Rules

These rules apply unconditionally. There is no exception for a file that has grown large,
no exception when the prior entry seems wrong, and no exception when the concept has been
superseded entirely.

### Byte-for-byte preservation outside the change surface

Every heading, code block, paragraph, and blank line outside the section being modified
is preserved character-for-character. The only way the agent changes those regions is via
the front matter `last-updated` date.

If an agent finds itself wanting to reorder sections, rename headings, or reformat
surrounding content, the correct action is to make a note in the diff report: "file
organization could be improved; trigger /learn review via technical-writer." The agent
does not reorganize unilaterally.

### Correction: supersede, never delete

When a prior entry states something incorrect or outdated:

1. Do not overwrite the prior text.
2. Mark it superseded with a blockquote marker including the date and reason.
3. Write the corrected understanding below.
4. The superseded text remains visible forever.

Multiple corrections to the same concept accumulate. After three corrections, the section
has three layers of supersession markers followed by the current understanding at the
bottom. This is the design. The learner can see exactly how their understanding evolved,
which prior framing was closest to correct, and what changed each time.

### Refinement: preserve prior phrasing as Prior Understanding

When an entry is correct in substance but imprecise in phrasing:

1. Write the refined version in the active position (where the prior text was).
2. Move the prior text to a dated `Prior Understanding (revised YYYY-MM-DD)` block below.
3. The prior text remains visible, attributed to its revision date.

### No summarization or compression

An agent must never summarize or compress prior entries to reclaim space. Compressing
prior content destroys exactly the kind of information that makes the knowledge base
valuable months later: the exact wording of an earlier understanding, the specific example
that was used, the naive framing that was corrected. Superseded entries accumulate with
their markers. This is the design, not a cost to optimize around.

---

## 6. Cross-Domain Teaching Moments

When a teaching moment spans two or more domains:

**Primary placement rule:** Place the full explanation in the domain where the concept is
most foundational. If the concept is about how the repository pattern enforces a boundary
between domain logic and persistence, the full explanation belongs in `architecture.md`
(where module boundaries live) rather than `persistence-strategy.md`.

**Secondary placement rule:** In the secondary domain file, write a cross-reference link
only. Do not repeat the explanation.

```markdown
## Repository Boundary (cross-reference)

The repository pattern's enforcement of the domain-persistence boundary is documented
in detail in [architecture.md: Repository Pattern](./architecture.md#repository-pattern).
This section notes the persistence-side implications: [one or two sentences specific to
the persistence domain, then the link].
```

**Cross-reference link format:** Use relative Markdown links from one notes file to another.

```markdown
[Repository Pattern](./architecture.md#repository-pattern)
[Error Propagation across layers](./error-handling.md#boundary-crossing)
```

Heading anchors are lowercase, hyphens replace spaces, punctuation is dropped. This
matches GitHub Markdown anchor behavior.

**Cross-references are always written, even under focus restrictions.** When `focus_domains`
is set and the secondary domain is not in focus, the cross-reference link is still
created. It costs one line and preserves navigability. The full explanation is deferred
to the primary domain entry.

---

## 7. New-Domain Creation

Agents never auto-create domain files. The invariant:

1. Agent identifies a teaching moment with no matching canonical domain.
2. Agent proposes the domain in the diff report using the format in Step 1 above.
3. Learner runs `/learn domain new <key>`.
4. The `/learn` Skill creates the seeded file with front matter and a Placeholder section.
5. On the next session where the agent has a teaching moment for that domain, the agent
   reads the (now existing) file and applies the enrichment protocol normally.

Between Step 2 and Step 5, the teaching moment is captured in the diff report as a
proposal. The content is not lost — the learner can see what would have been written and
choose whether to create the domain.

The seeded file shape the `/learn` Skill creates:

```markdown
---
domain: <key>
last-updated: <YYYY-MM-DD>
contributing-agents: []
---

# <Title-Cased Key>

This is a custom domain opened by the learner. It covers concepts that do not fit
cleanly into the 19 canonical domains defined in .claude/meta/references/domain-taxonomy.md.

Agents contribute here only when their Learning Domains section includes this key.
The enrichment protocol is defined in .claude/skills/learn/preamble.md.

## Placeholder

This section is seeded empty. The first agent with a teaching moment in this domain
will replace this placeholder with a real section following the enrichment protocol
in .claude/skills/learn/preamble.md.
```

Agents replace the Placeholder section with the first real section. The Placeholder
heading and its paragraph are removed when a real section is added — this is the one case
where an existing section may be replaced: the Placeholder is not real content.

---

## 8. What Agents Must Not Do

These prohibitions apply unconditionally at every level and for every domain.

### No pedagogical content in code or artifacts

Do not modify code comments, inline documentation, generated artifacts, or any file
outside `.claude/learn/knowledge/` to add pedagogical content. Additionally, do not
read, cite, or write under `.claude/meta/references/examples/` (which holds both `*.md`
and `*.ja.md` worked examples) — these are read-only references for forkers, not part
of the live learner surface.
If a teaching moment belongs in a code comment, put it in the domain knowledge file and
cross-reference it from the diff report. The production code files are not the knowledge base.

### No softening of review severity

Do not soften, hedge, qualify, or dilute severity labels on code-reviewer findings. A
CRITICAL finding is CRITICAL at junior, mid, and senior levels. A learning note that
explains why a finding is CRITICAL is additive and encouraged; it does not change the
severity label. The learning section appears after the finding, not as a qualification of it.

### No affirmation filler

Do not include "Great question", "Well done", "Excellent work", "Good catch", or any
variant of affirmation language in any output. Learning content is informational. The
learner's behavior is not being evaluated by the agent.

### No session-specific narration in knowledge files

Do not write session-specific context into domain files. "In this session we decided...",
"While debugging the cache miss...", "Today we encountered..." are session logs, not
domain knowledge. Extract the principle from the session event and write the principle. The
per-response diff report is the only session-level record; domain files contain distilled
understanding.

### No quizzes or comprehension checks

Do not ask the learner to answer a question before presenting the deliverable. Do not
structure learning content as a question. Do not gate the artifact on a learning prompt.
The artifact is always first. Learning sections always follow. The learner is not asked to
demonstrate understanding before proceeding.

### No curriculum or sequencing

Do not order learning contributions for pedagogical progression. Domain files are organized
by concept, not by learning sequence. Each entry is a standalone record in the relevant
section. There is no curriculum.

---

## 9. Focus Domain Behavior

When `config.focus_domains` is a non-empty array, the following rules apply to teaching
moment decisions.

**In-focus primary domain:** Full enrichment entry at the declared level. Behavior
identical to unfocused Learning Mode.

**Out-of-focus primary domain, genuinely load-bearing moment:** Write normally. A
teaching moment is load-bearing if omitting it would leave a gap that the learner is
likely to encounter again, if it explains a non-default choice that shapes the artifact
just produced, or if a future agent in the same session will build on it. Load-bearing
moments are never deferred because the domain is not in focus.

**Out-of-focus primary domain, marginal moment:** Defer. A teaching moment is marginal
if it is a secondary observation, a minor nuance that enriches but does not anchor
understanding, or a cross-reference that could be written on the next occasion the
domain is worked. Deferring means writing nothing for this moment — not writing a
shorter version of what would have been written.

The judgment call — load-bearing versus marginal — is made per teaching moment, not per
domain. An agent whose primary domain is not in focus may write zero entries in a session,
or may write one genuinely load-bearing entry, or may write several if the work happened
to involve non-default choices in that domain.

**Cross-references are always written** regardless of focus. A cross-reference link from
an out-of-focus domain to an in-focus domain costs one line and preserves navigability.
The rule against marginal entries does not suppress cross-references.

This focus model means the learner can say "I am studying concurrency this month" and
the knowledge base intensifies teaching effort in `concurrency-and-async` without going
silent on everything else. Genuinely important teaching moments from any domain remain
visible. The focus signal changes the threshold for what counts as worth recording outside
the focus list, not what counts as worth understanding.

---

## 10. Orchestrator Serialization for Concurrent Domain Writes

When the orchestrator delegates to two or more agents in a single workflow turn, and
those agents have overlapping Learning Domains, they must not write to the same domain
file in parallel. The invariant: a domain file write is a read-modify-write cycle, and
two concurrent read-modify-write cycles that start from the same pre-edit file will lose
one agent's contribution when the second write commits.

**The rule the orchestrator follows:**

Before dispatching agents in parallel, inspect the Learning Domains lists of all agents
to be dispatched. If any two agents share at least one domain key, the agents that share
domains must run sequentially — the first agent completes its full enrichment cycle
(including writing the domain file), then the second agent starts from the updated file.

Agents with entirely disjoint Learning Domains may run in parallel without restriction.
Their domain file writes cannot conflict.

**Example:**

Architect (Primary: `architecture, api-design, data-modeling`) and
code-reviewer (Secondary includes `architecture`) share `architecture`. The orchestrator
must sequence their learning-writing phases: architect writes first, code-reviewer reads
the updated `architecture.md` before writing its own contribution.

**This is an orchestrator-side concern.** This preamble documents the rule so agents
understand why they may be sequenced rather than parallelized, but enforcement is the
orchestrator's responsibility. An agent that finds itself writing to a domain file after
another agent in the same session should always read the current file state before writing
— the Step 2 read is required, and if another agent wrote to the file in the same session,
the current file is the one that agent left behind.

If the orchestrator parallelizes two agents with overlapping domains and a write conflict
occurs, the session contract's diff report will show which operation was lost (one agent's
diff report will not match what is in the file). The learner can ask the agent to retry
the enrichment from the post-conflict file state.

---

## 11. Knowledge Tier Hierarchy

When writing a teaching moment, cite the most specific applicable source.

**Tier 1 — External canonical documentation:** Official language or framework docs,
named patterns (Martin Fowler's catalog, Gang of Four, OWASP, RFC specifications). Cite
by named pattern when a specific URL may go stale. If a URL is stable and accessible,
include it. Do not fabricate citations. If the URL is not directly accessible in the
current session, cite by pattern name and note that the learner should verify the source.
A fabricated citation is worse than no citation.

**Tier 2 — Project ADRs:** Records in whatever ADR directory this project uses (scaffolded from `.claude/templates/adr-template.md`). Cite by ADR number and short
title (`ADR-001: developer-growth-mode`). Verify that the ADR file exists before citing
it by number. Do not generate Tier 2 citations for ADRs that have not been written. If
the decision has not been formally recorded, note that the reasoning is local convention
and flag it as a candidate for an ADR.

**Tier 3 — Prior domain entries:** Entries already in `.claude/learn/knowledge/` from prior
sessions. Use to build on what exists and to add cross-references. Tier 3 is the lowest
authority; prior entries establish what the learner has already encountered, not ground
truth.

---

## 12. Domain File Front Matter Convention

When writing to a domain file, update the front matter as follows:

```yaml
---
domain: <domain-key>
last-updated: <YYYY-MM-DD of this write>
contributing-agents: [<list of contributing agent names, updated as agents write here>]
---
```

If this agent's name is not already in the `contributing-agents` list and this agent is writing
content to the file, add this agent's name. The `contributing-agents` field is a record of which
agents have contributed, not a permission gate.

---

## 13. Voice and Longevity Rules

Domain files are written to be re-read months later, out of session context.

**Voice:** Neutral and explanatory. Not session-personal. Avoid "we decided", "I
discovered", "you should remember". Use "the project", "this pattern", "in Go",
"the preferred approach".

**Tense:** Present tense for enduring truths ("event sourcing separates write models
from read models"). Past tense for project decisions with a specific historical context
("this project chose PostgreSQL in 2025 because...").

**Naming:** Name patterns and concepts explicitly. Avoid pronouns that require session
context ("it was better than the alternative" → "event sourcing adds observability at the
cost of eventual consistency").

**Anti-patterns that agents must not write into domain files:**

- Session-specific commit SHAs. Use ADR references or permanent section links instead.
- Private PII or secrets of any kind.
- Blame language ("the old code was a mess"). Focus on the pattern and the reason for
  the change.
- Quizzes ("Can you think of why..."). Explain the reason.
- Affirmation ("Great job noticing..."). State facts.
- "As of [date], the framework doesn't support X." Use conditional framing: "The framework
  historically lacked X; if this has changed, update this section."
- Session-specific narration. Extract the principle; the per-response diff report is the
  session-level record.

---

## 14. Cross-Reference to Supporting Files

- **Config:** `.claude/learn/config.json` — state file read at session start.
- **Toggle Skill:** `.claude/skills/learn/SKILL.md` — the only surface through which
  config is written.
- **Domain files:** `.claude/learn/knowledge/<domain>.md` — 19 canonical domains plus any
  learner-opened custom domains; files are lazy-materialized on first teaching moment.
- **Domain taxonomy (authoritative):** `.claude/meta/references/domain-taxonomy.md` — canonical
  definitions, scope boundaries, and per-agent ownership matrix.
- **Worked examples (read-only references):** `.claude/meta/references/examples/<domain>.md` —
  realistic populated knowledge files from a shared fictional project (Meridian),
  one file per canonical domain. Agents never read, cite, or write under this tree.
- **Architecture decision records:** `.claude/meta/adr/001-developer-growth-mode.md` (original
  design, partially superseded), `.claude/meta/adr/002-growth-domains-location.md` (prompt-body
  declaration), `.claude/meta/adr/003-learning-mode-relocate-and-rename.md` (v2.0.0 rename and
  relocation).
- **CLAUDE.md pointer:** `.claude/CLAUDE.md` — the `## Developer Learning Mode` block that
  agents discover on session start.
- **Coaching pillar ADR:** `.claude/meta/adr/004-coaching-pillar.md` — architecture decision for
  the coaching pillar (v2.1.0).
- **Coach style files:** `.claude/skills/learn/coach-styles/<style>.md` — one file per style;
  loaded at guard time when `coach.style` is non-`default`.

---

## 15. Coaching Pillar Overview

The **coaching pillar** is the second axis of Developer Learning Mode. The knowledge pillar
(§§1–14 above) is post-hoc and passive: agents produce their artifact, then record what they
taught. The coaching pillar is in-session and active: it changes how the agent works during
implementation, not only after.

The coaching pillar ships six styles — the inert `default` plus five active behavior modes —
each expressed in a style file under `.claude/skills/learn/coach-styles/`. Which style is
active is controlled by `coach.style` in `.claude/learn/config.json`. Like the knowledge pillar, the
coaching pillar is default-off. A config with no `coach` key — including every v2.0.0 config
— resolves to `coach.style = "default"`, which is byte-identical to coach-off. No behavior
changes for existing installs.

The two pillars are orthogonal axes: either can be on or off independently. They do not
constrain each other. Knowledge pillar on, coaching off is v2.0.0 behavior. Coaching on with
knowledge off means the agent coaches without producing a knowledge base. Both on means both
layers stack. The `disable-model-invocation: true` invariant on the `/learn` Skill extends to
every coach subcommand: the learner — not the model — selects the coaching style.

---

## 16. Coach Style Resolution

At guard time (when the agent reads `.claude/learn/config.json` at session start), the agent resolves
the active coaching style by this read order:

1. Read `.claude/learn/config.json`. If absent or invalid, treat as `coach.style = "default"`.
2. Read `config.coach.style`. If the key is absent, null, or not one of the six canonical
   style names, treat as `"default"`.
3. Look up the file at `.claude/skills/learn/coach-styles/<style>.md`. If the file exists,
   load its `behavior-rule:` frontmatter field and apply it for this turn. If the file is
   missing, fall back to `"default"` and emit a warning on the next `/learn status` output.
4. If `coach.style` is `"default"` (by resolution or explicit config), apply no coaching
   modifications. Agent output is byte-identical to a world without the coaching pillar.

This resolution runs once at guard time and is stable for the turn. Mid-turn style changes
are not possible. A `/learn coach <style>` invocation takes effect on the next agent turn.

---

## 17. Per-Style Behavior Contracts

The following rules are stated in imperative voice. Each applies for every agent turn
produced while the named style is active.

**`default`:** Work normally. No withholding, no extra teaching scaffolding, no `## Coach:`
trailing section. Functionally identical to coaching off.

**`hints`:** Identify the next concrete implementation step. Name the relevant pattern or API.
Write scaffolding only (imports, signatures, test stubs). Do not write the body of the target
function. Emit a `## Coach: hint` block containing the step name, the pattern name, and a
one-line rationale. Place `<!-- coach:hints stop -->` immediately after the hint block and
stop. No further implementation code follows in this turn. One hint per turn; no multiple
hints, no worked examples.

**`socratic`:** When the learner asks a how or why question, reply with exactly one focused
question that, if answered, picks the design decision the learner must make next. Do not write
code in the same turn as the question. Do not answer the question yourself. Place
`<!-- coach:socratic stop -->` immediately after the question block. On the learner's next
turn, resume normal behavior and implement based on the learner's chosen direction.

**`pair`:** Write complete scaffolding for the requested artifact. At each load-bearing
decision point, insert `// TODO(human): <one-line instruction>` instead of the implementation.
Cap TODO markers at roughly 30% of the changed lines so the scaffolding is a genuine skeleton.
Write the full test suite so the learner has a runnable red target. Place
`<!-- coach:pair stop -->` at the end of the response. Never write an algorithm body where a
TODO marker belongs.

**`review-only`:** Refuse to write production code. When asked to implement, decline and
explain the active style. Read submitted or on-disk code and produce a structured review using
CRITICAL/HIGH/MEDIUM/LOW severity levels. Writing tests is permitted when the learner
explicitly requests them. Place `<!-- coach:review-only stop -->` at the end of the review.
Never soften severity labels because the learner authored the code.

**`silent`:** Work normally. Suppress every `## Learning: taught this session` and
`## Learning: knowledge diff` trailing section. Suppress any `## Coach:` section. The response
ends with the last line of the primary artifact. Knowledge files are still written if the
knowledge pillar is enabled; only the chat-visible trailers are omitted. No stop marker is
emitted (there is no coach section to terminate). This suppression persists across turns until
the learner changes the style; it is not per-turn like `/quiet`.

---

## 18. Coach × Knowledge Composition

The two pillars operate independently. The interaction rules below govern the edge cases where
they share a surface.

**`socratic` + knowledge on:** A Socratic question can itself be a teaching moment. If the
question reveals a load-bearing concept — one the learner must understand to answer it — the
agent writes that concept to the appropriate domain file following the knowledge pillar
protocol (§§1–5). The `## Learning:` trailing sections appear in the same response as the
question, before the stop marker. The knowledge write and the question coexist in the same
turn.

**`silent` + knowledge on:** Knowledge files are still written. The knowledge pillar protocol
runs normally: the agent reads the domain file, performs the enrichment operation, and writes
the updated file to disk. Only the chat-visible `## Learning:` and `## Coach:` trailing
sections are suppressed. The learner can verify that writes occurred by running `/learn status`,
which always reports the last-N knowledge diffs regardless of trailer suppression.

**`review-only` + knowledge on:** The review itself can produce teaching moments. A CRITICAL
finding that explains why a pattern is dangerous is a teaching moment. The knowledge pillar
protocol runs normally and the `## Learning:` trailing sections appear after the review block
and before the stop marker. (Styles are mutually exclusive — exactly one is active at a time
— so `review-only` and `silent` cannot both be on; the learner switches one for the other.)

**Level does not couple to coach style:** `level: junior` does not auto-select `hints` or any
other coach style. Level controls the angle of explanation; coach controls the shape of the
agent's work. The two axes do not constrain each other.

---

## 19. Coach Trailer Format

When a coaching style produces output that warrants a visible coaching section — styles other
than `default` and `silent` — the coaching section uses this heading format:

```
## Coach: <style-specific label>
```

Examples from each non-silent style:

- `hints` → `## Coach: hint`
- `socratic` → `## Coach: question`
- `pair` — no separate coaching section; TODO markers are embedded in the scaffolding code
- `review-only` → `## Coach: review`

The coaching section appears after the primary artifact and before the `## Learning:` trailing
sections (if the knowledge pillar is also on). Ordering: artifact → coach section → stop
marker → learning trailers.

**Suppression rules:**

- Under `silent` style: no `## Coach:` section is emitted. No `## Learning:` sections are
  emitted. The response ends after the primary artifact.
- Under `coach.trailers: never` in config: same as `silent` style for trailer suppression,
  but does not affect other coaching behavior. The style's behavior rule still runs; only the
  chat-visible trailing sections are omitted.
- Under `coach.trailers: always`: trailers are emitted even when the knowledge pillar is off.
  The `## Coach:` section appears if the style produces one; `## Learning:` sections are
  omitted if the knowledge pillar is off.
- Under `coach.trailers: auto` (the default): coaching sections appear when the active style
  would normally produce one; `## Learning:` sections appear when the knowledge pillar is on.

---

## 20. Style File Format

Coaching style files are authored in Output Styles–compatible Markdown: YAML frontmatter
followed by a prose body. The frontmatter carries four fields:

```yaml
---
name: <style-name>
description: <one-line description>
behavior-rule: >
  <imperative deterministic rule the agent applies at turn time>
stop-markers:
  - "<stop-marker-string>"
---
```

Field semantics:

- `name` — the style identifier that must match the filename stem and the `coach.style` value
  in config. Case-sensitive. One of the six canonical values or a drop-in custom style name.
- `description` — one line, used by `/learn coach list` when enumerating available styles.
- `behavior-rule` — the imperative rule the agent applies every turn while this style is
  active. Stated in present-tense second person ("Write scaffolding only. Do not write the
  body..."). This field is the enforcement surface; its content must be unambiguous.
- `stop-markers` — a list of HTML comment strings the agent emits to delimit the coaching
  output. Empty list for `default` and `silent`, which have no coaching output to terminate.
  Stop markers are grep-able assertions that the style ran. CI check 5 (in
  `.claude/meta/scripts/check-learn-invariants.sh`) verifies that each canonical file has a `behavior-rule:`
  key; stop markers are verified by checking agent responses rather than by CI.

Style files are loaded at guard time, not at session start. The agent reads the style file
only when the active style is non-`default` and the file exists. This keeps session-start
context cost proportional to whether coaching is active. New styles are added by dropping a
`.md` file into `.claude/skills/learn/coach-styles/` — no code change required. The
`/learn coach list` command discovers them by enumerating the directory.
