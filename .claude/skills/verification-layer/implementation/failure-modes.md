# Implementation domain — failure modes

> Five typical patterns that appear when the implementation
> verification is run without discipline. Each entry: pattern,
> what it looks like, why it happens, the checklist item that
> guards it.

## 1. Diff-priming

**What it looks like.** The Critic produces an implementation that
differs from the Generator's only in superficial ways — a renamed
variable, a slightly different `if` order — and reports "no
meaningful delta."

**Why it happens.** The Critic read the Generator's diff before
writing its own draft and unconsciously anchored to the same
solution shape.

**Guard.** Process gate **1** — read the spec, not the diff, first.
The Critic may consult the Generator's code only after its own
draft is committed to a scratch branch.

---

## 2. Library swap that ignores the user

**What it looks like.** The user wrote "use Drizzle, not Prisma."
The Critic re-implemented in Prisma "to compare," produced a
behavioural delta, and the PR author wasted thirty minutes
discussing differences that were never going to inform the
decision.

**Why it happens.** The Critic treated the four-level ranking as
"climb until you find a delta" rather than "lowest level that
yields a meaningful delta, respecting constraints."

**Guard.** Process gate **3** — user-library precedence is
permanent. The Critic's review header must declare the constraint;
silently picking a different library is a process violation, not
a finding.

---

## 3. Silent environment expansion

**What it looks like.** The Critic decided level 4 was the right
comparison, ran `brew install <X>` or `docker pull <Y>` to make it
work, and produced a clean review. The next contributor on a fresh
machine cannot reproduce.

**Why it happens.** "Just install it" feels harmless on the
Critic's own machine. It is not — verification on a learner's
laptop must be reproducible.

**Guard.** Process gate **4** — environment is unchanged. If level
4 is needed, emit the blocked-note and let the PR author decide.
The Critic does not unilaterally expand the project's environment.

---

## 4. Empty PASS

**What it looks like.** The review's findings table is empty. The
verdict is "PASS." There is no statement that the implementations
agreed, no list of what was actually compared, and no test count.
The PR author cannot tell whether the verification ran at all.

**Why it happens.** Silence is cheaper than narration. The Critic
reasoned that "no findings = pass" and stopped writing.

**Guard.** Quality gate **7** — silence is broken. A PASS verdict
must be paired with the explicit phrase "agrees on all observable
behaviour" plus the test count. Empty PASS is a process error.

---

## 5. Performance theatre

**What it looks like.** The behavioural delta table is dominated
by lines like "Critic implementation 1.2µs faster on test_foo (p
< 0.001)" for code paths that run once at startup. Real
behavioural deltas are buried below.

**Why it happens.** Microbenchmarks are easy to produce and look
rigorous. They drown the signal that mattered.

**Guard.** Quality gate **9** — performance is a finding only
when the delta crosses a user-visible threshold (latency budget,
allocation count, cold-start time). Below the threshold, it is
omitted.

---

## See also

- [protocol.md](./protocol.md) — full implementation-domain
  protocol including the four-level ranking
- [checklist.md](./checklist.md) — Critic checklist (10 items)
- [`.claude/agents/adversarial-implementer.md`](../../../agents/adversarial-implementer.md)
  — Critic agent prompt
