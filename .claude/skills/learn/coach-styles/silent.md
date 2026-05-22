---
name: silent
description: Agent works normally but suppresses every Learning trailer section for the lifetime of this style.
behavior-rule: >
  Work normally. Produce the artifact exactly as in default mode. Suppress every
  `## Learning: taught this session` and `## Learning: knowledge diff` trailing section
  for every response produced while this style is active. Do not emit any `## Coach:`
  trailing section. Knowledge files are still written if the knowledge pillar is enabled;
  only the chat-visible trailer is omitted. This suppression persists until the style is
  changed, unlike /quiet which suppresses for one turn only.
stop-markers: []
---

# Silent

The `silent` style is the inverse of teaching mode. The agent works normally — implements
the artifact, applies the knowledge pillar if enabled, writes domain files as usual — but
suppresses every `## Learning:` and `## Coach:` trailing section in the chat response. The
learner is in flow and does not want pedagogy noise cluttering the output.

## When to use

Use `silent` when:

- You are in a focused implementation sprint and the trailing sections interrupt your
  reading of the response.
- You are pair-programming at speed and want the raw artifact, not the annotation.
- You enabled Learning Mode for accumulation purposes but do not want to see the diff
  trailers during a particularly dense session.
- You want to disable trailer noise without disabling the knowledge base accumulation
  (which disabling Learning Mode entirely would do).

## Difference from `/quiet`

`/quiet` is a one-turn trailer suppressor: it suppresses the trailers for a single agent
response and then restores normal trailer behavior automatically on the next turn. `silent`
is a persistent style: it suppresses trailers for every turn until the learner explicitly
changes the coaching style. They serve different authorship patterns:

- `/quiet` — "just for this one response, skip the trailers."
- `silent` style — "for the rest of this session (or until I change styles), skip all
  trailers."

Both mechanisms can coexist: if the learner is in `silent` style and also sends `/quiet`,
the `/quiet` has no additional effect because trailers are already suppressed.

## What the agent does

1. Produces the primary artifact normally, applying all normal agent behavior.
2. Applies the knowledge pillar protocol normally — reads the domain file, performs the
   enrichment operation, writes the updated domain file to disk — if the knowledge pillar
   is enabled.
3. Does NOT emit `## Learning: taught this session`.
4. Does NOT emit `## Learning: knowledge diff`.
5. Does NOT emit any `## Coach:` section.
6. Produces no trailing sections at all. The response ends with the last line of the
   primary artifact.

## What the agent does NOT do

- It does NOT skip knowledge file writes. The knowledge base continues to accumulate
  silently. The learner can run `/learn status` to see the last-N knowledge diffs and
  confirm that writes occurred.
- It does NOT apply any other coaching behavior (withholding, Socratic questions, TODO
  markers). `silent` is purely a trailer suppressor; normal implementation behavior
  continues.
- It does NOT emit a stop marker. There is no `## Coach: silent` section to terminate.
  The response simply ends without trailing sections.

## Verifying silent writes

Because knowledge file writes happen without a visible trailer, learners using `silent`
can verify accumulation by running `/learn status`, which always reports the last-N
knowledge diffs regardless of trailer suppression. The diffs are visible there even if
they were never surfaced in the chat.

## Knowledge pillar interaction

In `silent` mode with the knowledge pillar on, `socratic` questions can still be teaching
moments (per ADR-004 §4). If the agent happens to be running a style switch that restores
`socratic` within a `silent` session, the knowledge pillar writes the teaching moment
to disk. The trailer that would have reported it remains suppressed. The style switch
is the learner's explicit action; the suppression is the learner's explicit choice.

## Scope and persistence

`silent` persists until the learner runs `/learn coach <other-style>` or
`/learn coach off`. It is not session-bounded by default (it respects `coach.scope`). If
`coach.scope: session`, the style resets to `default` at session end, same as all other
non-default styles.
