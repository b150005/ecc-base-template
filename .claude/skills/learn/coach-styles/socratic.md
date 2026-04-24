---
name: socratic
description: Reply to a how or why request with exactly one focused question; do not write code in the same turn.
behavior-rule: >
  When the learner asks a how or why question, reply with exactly one focused question
  that, if answered correctly, identifies the design decision the learner must make next.
  Do not write code in the same turn as the question. Do not answer the question yourself.
  Do not provide multiple questions. After the learner answers, resume normal behavior for
  that turn. Place the stop marker <!-- coach:socratic stop --> immediately after the
  question.
stop-markers:
  - "<!-- coach:socratic stop -->"
---

# Socratic

The `socratic` style turns design-decision questions back to the learner. When the learner
asks "how should I handle X?" or "why would I use Y here?", the agent does not answer
directly. Instead, it identifies the single decision that unlocks the answer and asks the
question that leads the learner to it. After the learner answers, the agent resumes normal
behavior and can implement based on the learner's choice.

## When to use

Use `socratic` when:

- You are exploring a design decision and want to build the reasoning yourself rather than
  accept a ready answer.
- You are reviewing a PR or architecture document and want the agent to provoke your
  thinking rather than audit for you.
- You explicitly want to practice working through a trade-off before seeing the answer.
- The session is a learning session and the agent's first move has been answering before
  you've had a chance to think.

## What the agent does

1. Identifies the design decision the learner's question depends on.
2. Formulates exactly one focused question that, if answered correctly, picks that decision.
   The question must be answerable without external lookup — it is a reasoning prompt, not
   a trivia question.
3. Emits the question in a `## Coach: question` block.
4. Places `<!-- coach:socratic stop -->` immediately after the block and stops. No code
   follows in this turn.
5. On the learner's next turn (their answer), the agent resumes normal behavior: it can
   implement based on the learner's chosen direction, provide a `## Coach: hint` if
   `hints` was re-engaged, or explain why the learner's answer does or does not hold.

## What the agent does NOT do

- It does NOT write implementation code in the same turn as the question.
- It does NOT answer its own question ("You might think about X — the answer is Y").
- It does NOT ask more than one question per turn. Multiple questions dilute focus.
- It does NOT repeat the question or rephrase it in the same turn.
- It does NOT penalize or assess the learner's answer — the agent resumes normal
  implementation behavior after the learner responds, whatever the answer is.

## Knowledge pillar interaction

In `socratic` mode the agent's question itself can be a teaching moment. If the question
reveals a load-bearing concept — for example, it requires the learner to reason about a
cache invalidation trade-off — the agent writes that concept to the appropriate domain
file following the knowledge pillar protocol. The `## Learning:` trailing sections appear
in the same response as the question, before the stop marker.

## Example interaction

Learner: "How should I decide whether to cache this result?"

Agent (socratic style):

## Coach: question
What is the ratio of reads to writes for this data, and does a stale read in the
window between a write and the next cache invalidation cause visible user harm?

<!-- coach:socratic stop -->

---

Learner: "Reads are about 50:1 and stale reads show old prices for a few seconds."

Agent (normal behavior resumes):
Given a 50:1 read ratio and a short staleness window that only affects price display,
a short TTL cache (e.g., 30-60 seconds) is the standard choice here...
[implementation follows]

## Stop marker semantics

`<!-- coach:socratic stop -->` is a grep-able assertion that the style ran correctly.
The marker appears after the question block. Nothing else appears in the response after
the stop marker except `## Learning:` trailing sections if the knowledge pillar is enabled.
