---
name: quiet
description: >
  Suppress trailer sections (teaching-provenance and knowledge-diff) from the
  immediately following agent response without disabling Learning Mode writes or
  any other agent behavior. Works when Learning Mode is on (suppresses learning
  trailers) and generalizes to any future Skill that appends ## <prefix>:
  trailer sections — /quiet suppresses all of them for that one response.
disable-model-invocation: true
arguments: []
---

# /quiet — Per-Invocation Trailer Suppression

## Purpose

`/quiet` tells the agent producing the current response to omit all trailing
`## <prefix>:` sections from its chat output. The effect is limited to the
single response being produced. No state is written. The next user turn
automatically restores normal trailer behavior.

When Learning Mode is on, the suppressed sections are:

- `## Learning: taught this session`
- `## Learning: knowledge diff`

The domain files under `learn/knowledge/` are still updated normally.
Learning Mode is still on. The enrichment protocol runs as usual. Only the
chat-visible trailer is omitted.

---

## Invocation

Place `/quiet` anywhere in the user message — as a standalone line or inline
with other text. The agent detects the bare token `/quiet` in the current turn
and applies suppression to its response.

```
/quiet

Please review this PR and apply the enrichment protocol as usual, but I do not
need the learning trailer in this response.
```

or inline:

```
Review this function. /quiet
```

`/quiet` takes no arguments. Any text after `/quiet` on the same line is part
of the user message and is not parsed as an argument.

---

## What Gets Suppressed

Any trailing section whose heading matches the pattern `## <Word>: <rest>`
at the end of a response. Currently:

- `## Learning: taught this session` — the per-concept teaching summary
- `## Learning: knowledge diff` — the per-file operation report

Future Skill trailers that follow the same `## <Prefix>:` heading convention
are also suppressed, so `/quiet` remains useful as new features add trailers.

The suppressed sections are the only change. The primary artifact — code,
review, architecture decision, security report, or other deliverable — appears
in full.

---

## Scope

The current user turn only. Suppression is not persisted. No file is written.
No config field is set. The very next user turn resumes normal trailer behavior
without any action from the learner.

---

## Interaction With Learning Mode

| Learning Mode state | `/quiet` present | Trailers appear? | Knowledge base updated? |
|---------------------|-----------------|-----------------|-------------------------|
| off                 | no              | no              | no                      |
| off                 | yes             | no              | no                      |
| on                  | no              | yes             | yes                     |
| on                  | yes             | no              | yes                     |

When Learning Mode is off there are no trailers to suppress, so `/quiet` is
effectively a no-op for learning trailers. It remains defined behavior and
does not produce an error.

---

## What /quiet Does NOT Do

- Does not write to `learn/config.json` or any other file.
- Does not prevent the agent from reading `learn/preamble.md`.
- Does not prevent the agent from reading or updating domain knowledge files.
- Does not disable Learning Mode for the current or any future turn.
- Does not clear `focus_domains` or any other config setting.
- Does not carry over to the next user turn — scope is strictly one response.

---

## Why /quiet Is a Separate Skill

`/learn` controls whether the knowledge base is maintained. `/quiet` controls
whether the trailer is rendered. These are orthogonal decisions. A learner
may want silent background enrichment — the knowledge base accumulates, the
response stays uncluttered — which is different from wanting Learning Mode off
entirely. Keeping `/quiet` separate also lets it suppress trailers from future
Skills without becoming a grab-bag subcommand of `/learn`.

The `disable-model-invocation: true` flag means the model cannot invoke
`/quiet` on its own. Suppressing the trailer is a learner preference, not
a model optimization.

---

## Agent Detection Protocol

When an agent receives a user turn, before composing its response it checks
whether `/quiet` appears in the current message as a standalone
whitespace-delimited token, at the top level of the message (not inside a fenced
code block), and not as a substring of a longer identifier. If the rule matches,
the agent omits all `## <Prefix>:` trailing sections from its response. The check
is against the current turn only — prior turns are not inspected. No file read is
required; the signal is in the message itself.

Detection rule: `/quiet` triggers trailer suppression only when it appears in the
current turn's user message as a **standalone whitespace-delimited token, at the
top level of the message (not inside a fenced code block), and not as a substring
of a longer identifier**. Specifically:
- Matches: a line containing only `/quiet`, or `/quiet` preceded and followed by
  whitespace.
- Does NOT match: `/quiet` inside ` ``` ` fenced code blocks; `/quiet` inside
  inline code spans `` `/quiet` ``; `/quiet` as part of a longer word like
  `/quieting` or `/quieter`; flags like `--quiet` (different token).
- The detector is case-sensitive: `/QUIET` does not trigger.

---

## Cross-References

- Learning Mode toggle: `.claude/skills/learn/SKILL.md`
- Enrichment contract (what the knowledge base update does): `learn/preamble.md`
- Architecture decision: `docs/en/adr/001-developer-growth-mode.md` — `/quiet` section
- Config schema (does not include a quiet field): `learn/config.json`
