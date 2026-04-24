---
name: default
description: Agent works normally with no coaching behavior. Equivalent to coach-off.
behavior-rule: >
  Work normally. Apply no withholding, no extra teaching scaffolding, and no coaching
  modifications. Produce the artifact exactly as you would if the coaching pillar did not
  exist. This style is functionally identical to coach-off; selecting it explicitly is the
  same as having no coach.style key in config.
stop-markers: []
---

# Default

The `default` style is the null-coaching state. The agent works exactly as it would if
the coaching pillar were not installed: it produces the requested artifact, applies the
knowledge pillar if enabled, and emits no `## Coach:` trailing section.

## When to use

Use `default` (or `/learn coach off`, which is an alias) when:

- You want the agent to own the implementation fully and explain what it did after.
- The session is in a delivery phase and pedagogy scaffolding would slow you down.
- You want to switch off a previously active coaching style without leaving the `/learn`
  ecosystem entirely.
- You are on a time constraint and a `hints` or `pair` scaffold would add overhead.

## What the agent does

Nothing different from its normal operation. The agent reads the task, produces the
artifact, and — if the knowledge pillar is enabled — appends the `## Learning:` trailing
sections. No `## Coach:` section appears. No withholding of code. No Socratic questions.

## What the agent does NOT do

- It does NOT emit a `## Coach:` section. If you see one, that is a violation.
- It does NOT withhold any part of the implementation.
- It does NOT add any extra scaffolding or TODO markers beyond what it normally would.
- It does NOT treat the absence of a coaching marker as a signal to compensate with
  pedagogical commentary elsewhere in the response.

## Backward compatibility

A v2.0.0 config with no `coach` key resolves to `coach.style = "default"`. The output is
byte-identical to a v2.0.0 agent run. This is the default-off invariant for the coaching
pillar: adding the coaching pillar to v2.1.0 changes nothing for learners who do not opt
into a non-default style.

## Interaction with knowledge pillar

The knowledge pillar is unaffected. `default` coaching and knowledge-pillar-on is
v2.0.0 behavior. `default` coaching and knowledge-pillar-off is the same as having no
Learning Mode installed at all.
