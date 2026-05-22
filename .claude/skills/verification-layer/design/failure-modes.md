# Design domain — failure modes

> Five typical patterns that appear when the design verification
> is run without discipline. Each entry: pattern, what it looks
> like, why it happens, the checklist item that guards it.

## 1. Counter-proposal as restated rejection

**What it looks like.** The `## Counter-proposal` section reads
"we could have used X, but X has the obvious downsides Y and Z"
and stops there. The reader cannot reconstruct any positive case
for X.

**Why it happens.** The Critic interpreted the task as "explain
why the original choice is right" rather than "reconstruct the
rejected alternative as seriously as the original."

**Guard.** Quality gate **6** — `## Consequences` must have at
least two Positive bullets. A counter without any positive case
is not a counter-proposal; it is a louder rejection.

---

## 2. Same evidence, different paraphrase

**What it looks like.** The counter-proposal cites the same
vendor docs page the original ADR cited, with different prose.
The Critic produced no independent evidence base.

**Why it happens.** The Critic re-read the original ADR's
sources and treated them as authoritative. Same source = same
evidence; the verification mechanism collapses.

**Guard.** Quality gate **7** — different evidence base. A
different release tag, a different vendor docs section, an
RFC, a primary benchmark from the vendor's own repo. If no
different primary source exists, surface that as a constraint
on the original ADR's framing.

---

## 3. The "two valid options" cop-out

**What it looks like.** The counter-proposal's recommendation is
"both choices are reasonable; the team should pick based on
preference." The architect is left with no actionable input.

**Why it happens.** The Critic genuinely sees two valid options
and chose to be diplomatic about it.

**Guard.** Quality gate **8** — the counter recommends the
alternative, or the Critic flags that the original ADR's
framing is too loose to admit a real choice. "Both are fine" is
not a verdict.

---

## 4. Counter-proposal on a process ADR

**What it looks like.** The Critic produced a counter-proposal
to "ADR-NNN: rename `learn/` to `learning/`" arguing that the
rename should not happen.

**Why it happens.** The trigger conditions in `protocol.md` were
not consulted; the Critic verified everything on principle.

**Guard.** Process gate **2** — the design domain is for
decisions that affect downstream work. Pure naming / formatting
/ process ADRs are skipped. A counter-proposal on a rename adds
ADR length without adding decision quality.

---

## 5. Two competing counters, no commitment

**What it looks like.** The `## Counter-proposal` section
contains "Option A: …" and "Option B: …" — two parallel
counter-proposals — and ends without a recommendation. The
architect now has three choices to compare, not two.

**Why it happens.** The Critic could not pick which rejected
alternative to take seriously and presented both.

**Guard.** Process gate **3** — one counter per round. Pick the
alternative most likely to have been dismissed too quickly;
commit to it. The architect's response can request a different
alternative for the next round if needed.

---

## See also

- [protocol.md](./protocol.md) — full design-domain protocol
  including the seriousness bar
- [checklist.md](./checklist.md) — Critic checklist
- [`.claude/agents/architecture-critic.md`](../../../agents/architecture-critic.md)
  — Critic agent prompt
