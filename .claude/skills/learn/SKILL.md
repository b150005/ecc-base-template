---
name: learn
description: >
  Toggle Developer Learning Mode, manage per-domain focus for the living knowledge base at
  learn/knowledge/, and control the coaching pillar behavior. Learning Mode is a default-off
  learning layer with two orthogonal pillars: the knowledge pillar (agents contribute teaching
  moments to a domain-organized knowledge base) and the coaching pillar (agents change how
  they work during implementation based on a chosen coaching style).

  Supported invocations:
    /learn on [junior|mid|senior]        — Enable at the chosen level (default: stored level or junior)
    /learn off                           — Disable; preserve level and focus_domains for next enable
    /learn status                        — Print current config, coach state, and last-ten knowledge-diff summaries
    /learn focus <domain>[,<domain>]     — Narrow agent teaching effort to one or more domains
    /learn unfocus                       — Clear focus_domains; agents treat all domains equally
    /learn level <junior|mid|senior>     — Change level without toggling enabled state
    /learn domain new <key>             — Create a new custom domain file after learner confirmation
    /learn coach <style>                 — Set active coaching style (hints|socratic|pair|review-only|silent|default)
    /learn coach off                     — Equivalent to /learn coach default
    /learn coach list                    — List all available styles with their descriptions
    /learn coach show <style>            — Print a single style's behavior-rule
    /learn coach scope <session|persistent> — Set persistence scope for the coach subtree
    /quiet                               — One-shot suppression of Learning enrichment for the current
                                           session only (separate Skill at .claude/skills/quiet/SKILL.md)

  This Skill is the only surface through which Learning Mode state changes. Agents read
  learn/config.json; they never write it. disable-model-invocation: true is
  non-negotiable — the learner, not the model, decides when to enter teaching mode or
  change the coaching style.
disable-model-invocation: true
arguments:
  - name: action
    description: >
      on | off | status | focus | unfocus | level | domain | coach
      Maps the first positional token after /learn.
  - name: level
    description: >
      Optional second positional token. Meaning depends on action:
        on      → junior | mid | senior (the level to enable at)
        focus   → comma-separated domain key list, or "clear"
        level   → junior | mid | senior (the level to set)
        domain  → "new <key>" (the subargument for new-domain creation)
        coach   → <style> | off | list | show <style> | scope <session|persistent>
---

# Learn Skill Reference

## Invariant

This Skill is the single and exclusive mechanism for changing Learning Mode state.
No agent reads any toggle signal other than `learn/config.json`. No agent
writes `config.json` directly — agents read it on session start and act on it, but
only this Skill writes it back. This boundary is enforced at the platform layer by
`disable-model-invocation: true`, which prevents the model from auto-invoking `/learn`
on the learner's behalf. The learner chooses to be taught; the model does not choose
to teach.

Why this matters: Learning Mode changes every subsequent agent turn in the session. It
causes agents to spend additional context reading domain files and writing enrichment.
That decision must originate from the learner explicitly, never from the model deciding
"this session seems educational."

**Do not remove `disable-model-invocation: true`** from this file's frontmatter. If
you do, the platform loses the enforcement boundary and a future model turn can silently
flip the learner into teaching mode. The regression test (see Implementation Notes in
ADR-001) asserts that this flag is present and set to `true`; removing it fails CI.

---

## Config Schema

Learning Mode state persists in `learn/config.json`. The schema is fixed; unknown
keys are preserved on write for forward compatibility.

```json
{
  "enabled": true,
  "level": "junior",
  "focus_domains": [],
  "coach": {
    "style": "default",
    "trailers": "auto",
    "scope": "session"
  },
  "updatedAt": "2026-04-22T00:00:00Z"
}
```

Field semantics:

- `enabled` — boolean, required. If absent or unparseable, treated as `false`. A parse
  error on the entire file is treated as disabled without surfacing an error to the learner.
- `level` — string, one of `"junior"`, `"mid"`, `"senior"`. Required when `enabled: true`.
  Preserved when `enabled` is set to `false` so the next `/learn on` restores the last
  level without the learner having to restate it.
- `focus_domains` — array of domain key strings; may be empty. When non-empty, agents with
  a teaching moment outside the listed domains evaluate whether the moment is genuinely
  load-bearing; if marginal, they defer rather than produce a shallow entry. Full enrichment
  is written for teaching moments in a focus domain. This is a soft priority signal, not a
  hard filter — genuinely important teaching moments are never suppressed because they fall
  outside the focus list.
- `coach` — optional object; absent key resolves to `{ style: "default", trailers: "auto",
  scope: "session" }`. A v2.0.0 config without this key is treated identically to one with
  `coach.style = "default"`. No behavior change for existing installs.
  - `coach.style` — one of `default | hints | socratic | pair | review-only | silent`.
    A missing, null, or unrecognized value resolves to `"default"`. A style name with no
    matching file in `coach-styles/` also resolves to `"default"` with a warning on next
    `/learn status`.
  - `coach.trailers` — one of `auto | always | never`. Under `auto`, `silent` style
    suppresses trailers; every other style emits them when the knowledge pillar is on. Under
    `always`, trailers are emitted even when the knowledge pillar is off. Under `never`,
    trailing sections are suppressed for every style (equivalent to persistent `/quiet`).
  - `coach.scope` — one of `session | persistent`. Under `session`, the `coach` subtree
    resets to `{ style: "default", trailers: "auto" }` at the start of a new session (the
    Skill writes this reset on the first `/learn` invocation of a new session when
    `scope = session`). Under `persistent`, the style and trailers settings survive across
    sessions.
- `updatedAt` — ISO 8601 timestamp; set by this Skill on every write. Agents do not update
  this field.

The file is created on first `/learn on` invocation. It does not exist in the repository
before first use. Both `config.json` and `learn/knowledge/` are gitignored by default;
see `.gitignore.example` for the opt-in inversion if you want to commit notes.

---

## Handler Logic by Action

### `on` — Enable Learning Mode

**Argument shape:** `$action=on`, `$level=<junior|mid|senior>` (optional)

Step-by-step:

1. Read `learn/config.json` if it exists.
2. Determine the level to enable at:
   - If `$level` is provided and valid (`junior`, `mid`, `senior`), use it.
   - If `$level` is absent and a valid `level` is already stored in config, use the stored level.
   - If neither, default to `"junior"`.
3. Validate: if `$level` was provided but is not one of `junior`, `mid`, `senior`, print a
   usage error (see Validation section), do not write config, stop.
4. Write `config.json` with:
   - `"enabled": true`
   - `"level": <resolved level>`
   - `"focus_domains": <existing value or []>`
   - `"updatedAt": <current ISO 8601 timestamp>`
5. Print to the learner:

```
Learning Mode enabled.
  Level: junior
  Focus: all domains (no focus set)
  Knowledge base: learn/knowledge/

Agents will contribute teaching moments to the domain-organized knowledge base as they work.
Run /learn status to see current state. Run /learn off to disable.
```

When a non-empty `focus_domains` is already in config, replace "all domains" with
the domain list, e.g. `Focus: architecture, testing-discipline`.

---

### `off` — Disable Learning Mode

**Argument shape:** `$action=off`

Step-by-step:

1. Read `learn/config.json` if it exists.
2. Write `config.json` with:
   - `"enabled": false`
   - All other fields preserved (`level`, `focus_domains`, `updatedAt` updated to now).
3. Print to the learner:

```
Learning Mode disabled.
  Level (preserved): junior
  Focus (preserved): all domains

Run /learn on to re-enable at the same level and focus.
```

The preserved state means the learner does not have to restate level and focus on the next
enable. `/learn on` alone restores the previous configuration.

---

### `status` — Display Current State

**Argument shape:** `$action=status`

This action never writes config.

Step-by-step:

1. Read `learn/config.json`. If absent, report disabled state.
2. Read the last-ten knowledge-diff summaries from the learner's session history if available,
   or report "no recent diffs recorded" if the session has just started or the file does not
   exist. (Note: diff summaries are emitted as trailing sections in agent chat responses, not
   written to a file. The Skill reports the most recently visible ones in the current session
   context, or notes their absence if the session is new.)
3. Print a structured status block:

```
Learning Mode Status
──────────────────
Enabled:       true
Level:         junior
Focus domains: architecture, testing-discipline
Config path:   learn/config.json
Knowledge path:    learn/knowledge/
Last updated:  2026-04-22T14:30:00Z

Coach style:   hints
Coach trailers: auto
Coach scope:   session
  (scope=session: style resets to default at next session start)
Coach styles path: .claude/skills/learn/coach-styles/

Recent knowledge diffs (last 10, most recent first):
  1. knowledge/architecture.md → add on `## Repository Pattern`: introduced repository pattern with
     first-principles explanation and worked example.
  2. knowledge/testing-discipline.md → deepen on `## The Invariant Ladder`: added caveat about E2E
     test flakiness in async frameworks.
  [... up to 10 entries ...]

Domain files present:
  learn/knowledge/architecture.md
  learn/knowledge/api-design.md
  [... one line per file that exists ...]

Run /learn on [junior|mid|senior] to change level.
Run /learn focus <domain> to narrow teaching effort.
Run /learn coach <style> to change coaching style.
Run /learn coach list to see available styles.
Run /learn off to disable.
```

If config is absent or unparseable:

```
Learning Mode Status
──────────────────
Enabled:  false (no config file found)
Knowledge path: learn/knowledge/ (does not yet exist)

Run /learn on to enable. Default level: junior.
```

---

### `focus` — Set Focus Domains

**Argument shape:** `$action=focus`, `$level=<domain-csv>` or `$level=clear`

The second positional argument carries either a comma-separated list of domain keys or the
literal string `clear`.

**Clear focus** (`/learn focus clear` or `/learn unfocus`):

1. Read config.
2. Write config with `"focus_domains": []` and updated `updatedAt`.
3. Print:

```
Focus cleared. Agents will contribute teaching moments across all 19 canonical domains.
```

**Set focus** (`/learn focus <domain>[,<domain>]`):

1. Read config.
2. Parse the comma-separated domain key list from `$level`. Trim whitespace around each key.
3. Validate each key: it must exist as a `.md` file under `learn/knowledge/` (canonical
   or learner-opened custom domain). An unknown key that does not correspond to a file is an
   error. Print the error, do not write config. (The 19 canonical keys are always valid if the
   notes directory is seeded. Custom domains are valid only after the learner has created them
   via `/learn domain new <key>`.)
4. Write config with `"focus_domains": [<validated keys>]` and updated `updatedAt`.
5. Print:

```
Focus set: architecture, testing-discipline

Agents will write full enrichment entries for teaching moments in these domains.
Teaching moments in other domains are written only when genuinely load-bearing.
Run /learn unfocus to return to full-domain contribution.
```

---

### `unfocus` — Clear Focus (Alias)

**Argument shape:** `$action=unfocus`

Equivalent to `/learn focus clear`. Follows the same Clear focus step-by-step above.
Provided as a more natural invocation form. The argument `$level` is ignored for this action.

---

### `level` — Change Level Without Toggling Enabled State

**Argument shape:** `$action=level`, `$level=<junior|mid|senior>`

Step-by-step:

1. Read config.
2. Validate `$level`: must be `junior`, `mid`, or `senior`. If not, print usage error, stop.
3. Write config with `"level": <new level>` and updated `updatedAt`. `enabled` is unchanged.
4. Print:

```
Level changed to: senior

Learning Mode remains enabled. Future agent contributions will use the senior angle:
  senior — contributes only when a decision was non-default; captures the reasoning
  that would otherwise stay in the author's head. A senior session with all-default
  decisions writes zero notes, which is correct behavior.
```

Include the appropriate level summary for the selected level (see Level Semantics section).

---

### `domain new <key>` — Create a Custom Domain File

**Argument shape:** `$action=domain`, `$level=new <key>`

This action requires explicit learner confirmation before creating any file. Agents never
call this action automatically. Only the learner can trigger it.

Step-by-step:

1. Parse the domain key from `$level` after the `new ` prefix. The key is everything after
   `new ` with leading and trailing whitespace trimmed.
2. Validate the key:
   - Must contain only lowercase letters, digits, and hyphens.
   - Must not already exist as a file under `learn/knowledge/`.
   - Must not be one of the 19 canonical domain keys (those already exist).
   - Must be between 2 and 64 characters long.
   - If any validation fails, print a clear error describing the constraint, do not create
     any file, stop.
3. Print a confirmation prompt:

```
Create custom domain: <key>

This will create learn/knowledge/<key>.md with a seed placeholder. Agents will
be able to contribute teaching moments to this domain if their learning_domains include
it, but they will not auto-populate it until you explicitly work in this area.

This domain file is NOT an automatic fit for any existing agent's learning_domains.
To have an agent contribute here, you would need to add the key to that agent's
learning_domains declaration.

Confirm? [yes/no]
```

4. Wait for learner confirmation. If the learner responds with anything other than `yes`
   (case-insensitive), print "Cancelled. No file created." and stop.
5. On confirmation:
   a. Create `learn/knowledge/<key>.md` with seed content following the canonical shape:

```markdown
---
domain: <key>
last-updated: <YYYY-MM-DD>
contributing-agents: []
---

# <Title-Cased Key>

This is a custom domain opened by the learner. It covers concepts that do not fit
cleanly into the 19 canonical domains defined in docs/en/learn/domain-taxonomy.md.

Agents contribute here only when their learning_domains declaration includes this key.
The enrichment protocol is defined in learn/preamble.md.

## Placeholder

This section is seeded empty. The first agent with a teaching moment in this domain
will replace this placeholder with a real section following the enrichment protocol
in learn/preamble.md.
```

   b. Do not modify `focus_domains` in config unless the learner separately runs
      `/learn focus <key>`. Creating a domain does not automatically focus it.
   c. Print:

```
Created: learn/knowledge/<key>.md

The domain file is seeded and ready. It will be enriched by agents whose
learning_domains declaration includes "<key>". To narrow agent teaching effort to
this domain, run /learn focus <key>.
```

**Critical constraints for this action:**

- This Skill never writes pedagogical content into the new domain file beyond the seed
  placeholder. Knowledge content is agent territory; the Skill only creates the file
  structure. An agent writes the first real section when it encounters a teaching moment
  that belongs here.
- The Skill never modifies any existing file under `learn/knowledge/`. Notes are
  agent territory; the Skill creates new domain files only, and only on learner
  confirmation.

---

## Validation Rules

### Level values

`level` must be exactly one of `"junior"`, `"mid"`, `"senior"`. Comparison is
case-insensitive but the stored value is always lowercase.

Invalid level error:

```
Error: "<value>" is not a valid level. Use junior, mid, or senior.

Usage: /learn on [junior|mid|senior]
       /learn level [junior|mid|senior]
```

### Domain keys for `focus`

Domain keys passed to `/learn focus` must correspond to existing `.md` files under
`learn/knowledge/`. The 19 canonical keys are:

```
architecture          api-design           data-modeling
persistence-strategy  error-handling       testing-discipline
concurrency-and-async ecosystem-fluency    dependency-management
implementation-patterns review-taste       security-mindset
performance-intuition operational-awareness release-and-deployment
market-reasoning      business-modeling    documentation-craft
ui-ux-craft
```

Any learner-opened custom domain (created via `/learn domain new <key>`) is also valid
once its file exists.

Invalid domain key error:

```
Error: "<key>" is not a recognized domain. Valid keys are the 19 canonical domains
plus any custom domains you have created under learn/knowledge/.

Run /learn status to see which domain files are present.
```

### Unknown subcommand

If `$action` is not one of `on`, `off`, `status`, `focus`, `unfocus`, `level`, `domain`, `coach`:

```
Unknown subcommand: "<action>"

Usage:
  /learn on [junior|mid|senior]              — Enable Learning Mode
  /learn off                                 — Disable Learning Mode
  /learn status                              — Show current state
  /learn focus <domain>[,<domain>]           — Set focus domains
  /learn unfocus                             — Clear focus
  /learn level <junior|mid|senior>           — Change level
  /learn domain new <key>                    — Create a custom domain
  /learn coach <style>                       — Set coaching style
  /learn coach off                           — Reset to default (no coaching)
  /learn coach list                          — List available styles
  /learn coach show <style>                  — Show a style's behavior rule
  /learn coach scope <session|persistent>    — Set scope for coach subtree

Learning Mode state: learn/config.json
Enrichment protocol: learn/preamble.md
Domain taxonomy: docs/en/learn/domain-taxonomy.md
Coaching ADR: docs/en/adr/004-coaching-pillar.md
```

Unknown subcommands do not halt the session. They print the usage message and return.

---

## `coach` — Coaching Pillar Subcommand Group

**Argument shape:** `$action=coach`, `$level=<subcommand> [<arg>]`

The `coach` subcommand group manages the coaching pillar. All subcommands write
`learn/config.json` except `list` and `show`, which are read-only. The `disable-model-invocation:
true` flag applies to every subcommand: the learner — not the model — changes the style.

### `coach <style>` — Set Active Style

**Invocation:** `/learn coach hints` or `/learn coach default` etc.

Step-by-step:

1. Read `learn/config.json` if it exists.
2. Validate `<style>`: must be one of `default`, `hints`, `socratic`, `pair`, `review-only`,
   `silent`. If not, check whether a matching file exists at
   `.claude/skills/learn/coach-styles/<style>.md`. If a file exists with that stem, it is a
   valid custom style. If neither, print a validation error and stop.
3. Look up `.claude/skills/learn/coach-styles/<style>.md`. If the canonical style matches
   one of the six canonical names but the file is missing, accept the style and note the
   missing file in the output. The fallback to `default` happens at agent guard time, not
   at set time.
4. Write `config.json` with `coach.style` set to the validated style and updated `updatedAt`.
5. Print:

```
Coaching style set: hints

The agent will name the next step and relevant pattern, write scaffolding only,
and stop before implementing the target function body.

Run /learn coach off to reset to default (no coaching).
Run /learn coach list to see all available styles.
```

### `coach off` — Reset to Default

**Invocation:** `/learn coach off`

Equivalent to `/learn coach default`. Writes `coach.style = "default"` to config.
Prints:

```
Coaching style reset to default.

The agent will work normally with no coaching modifications.
```

### `coach list` — Discover Available Styles

**Invocation:** `/learn coach list`

This action never writes config.

Step-by-step:

1. Enumerate files matching `.claude/skills/learn/coach-styles/*.md`.
2. For each file found, parse the `name:` and `description:` from its YAML frontmatter.
3. Print one line per style, sorted alphabetically by name. Flag any file that is missing
   a `behavior-rule:` frontmatter key with `[WARNING: no behavior-rule]`.

```
Available coaching styles:
  default      — Agent works normally with no coaching behavior. Equivalent to coach-off.
  hints        — Name the next step and the relevant pattern or API; stop before writing the function body.
  pair         — Write complete scaffolding with TODO(human) markers at load-bearing decision points; tests written in full.
  review-only  — Refuse to write production code; read code and produce structured reviews; write tests if explicitly asked.
  silent       — Agent works normally but suppresses every Learning trailer section for the lifetime of this style.
  socratic     — Reply to a how or why request with exactly one focused question; do not write code in the same turn.

Active style: hints
```

Include custom drop-in styles if present (files not in the six canonical names).

### `coach show <style>` — Print a Style's Behavior Rule

**Invocation:** `/learn coach show hints`

This action never writes config.

Step-by-step:

1. Validate `<style>` against available files in `coach-styles/`.
2. Parse the `name:`, `description:`, and `behavior-rule:` from the file's frontmatter.
3. Print:

```
Style: hints
Description: Name the next step and the relevant pattern or API; stop before writing the function body.

Behavior rule:
  Identify the next concrete step toward the learner's goal. Name the relevant pattern or
  API. Write scaffolding only: imports, type signatures, function stubs, and test stubs.
  Do not write the body of the target function. Emit a `## Coach: hint` block containing
  the step name, the pattern or API name, and a one-line rationale for why that pattern
  applies. Place the stop marker <!-- coach:hints stop --> immediately after the hint block.

Stop markers:
  - <!-- coach:hints stop -->

File: .claude/skills/learn/coach-styles/hints.md
```

If the style name is not found, print an error and suggest `/learn coach list`.

### `coach scope <session|persistent>` — Set Persistence Scope

**Invocation:** `/learn coach scope session` or `/learn coach scope persistent`

Step-by-step:

1. Read config.
2. Validate the scope value: must be `session` or `persistent`.
3. Write `config.json` with `coach.scope` set to the validated value.
4. Print:

```
Coach scope set: session

The coach style and trailers will reset to their defaults at the start of each new
session. Run /learn coach scope persistent to keep the style across sessions.
```

When scope is `session`, the Skill writes `coach.style = "default"` and
`coach.trailers = "auto"` on the first `/learn` invocation of a new session. The first
invocation detection is heuristic: if the last `updatedAt` timestamp is older than 24
hours and scope is `session`, treat this as a new session and reset. The reset is logged
in the output of the first `/learn status` of the session.

---

## `/quiet` — Per-Invocation Suppression

`/quiet` is a separate Skill at `.claude/skills/quiet/SKILL.md`. It is not a subcommand
of `/learn`.

Effect: suppresses the `## Learning: taught this session` and `## Learning: knowledge diff`
trailing sections for the immediately following agent invocation. It does not disable
Learning Mode writes — the domain files are still updated. It only suppresses the visible
trailer in the chat response.

Detection: agents detect `/quiet` as a bare token in the current user turn's message.
No config file is written. The suppression applies to the one response being produced;
the next user turn restores normal trailer behavior automatically.

Authorship boundary distinction: `/learn` controls whether the knowledge base is maintained.
`/quiet` controls whether the session-contract trailer is rendered. These are orthogonal
decisions. A learner reading a long response in focused mode may not want the trailing
sections cluttering the output; that is a different decision from whether to continue
accumulating domain knowledge files. Keeping them separate lets `/quiet` remain useful even outside
Learning Mode (e.g., suppressing other trailing sections in the future) without becoming a
grab-bag subcommand of `/learn`.

---

## Level Semantics

Levels control the angle and density of foundational context — what the agent assumes the
learner already knows, and which decisions clear the threshold for a note. Levels are not
a verbosity knob and they do not set a token budget. Depth follows from the concept.

### junior

The agent explains from first principles. It introduces vocabulary before using it. It
names the pattern and contrasts it with the naive alternative a learner without prior
exposure would reach for. Worked examples are expanded. Prerequisite concepts are explained
inline or cross-referenced to the domain file that covers them. The agent does not assume
the learner has encountered this concept in any context.

A junior-level contribution is typically a full section with a first-principles explanation,
an idiomatic variation block, and a trade-offs block. That length is intended — it is
building foundational scaffolding.

### mid

The agent assumes first principles but explains the non-obvious. It focuses on what
idiomatic practitioners of this stack do that a competent engineer from another stack
would not guess. Trade-offs are named; alternatives are acknowledged without exhaustive
comparison. The agent skips scaffolding but still explains the why.

A mid-level contribution is typically one to three paragraphs, shorter than junior but
not terse.

### senior

The agent contributes only when a decision was non-default. The note names the default,
names the choice, and states why the choice was preferred in this context. A senior session
where every decision followed the default writes zero notes. That is correct behavior, not
a failure.

### All three levels write into the same domain files

The knowledge base does not fork by level. A junior foundational entry from session one and a
senior trade-off refinement from session twelve coexist in the same section. A senior
session encountering the repository pattern when a junior session already explained it
contributes a trade-off subsection, not a new first-principles explanation.

---

## Focus Domain Behavior

When `focus_domains` is non-empty:

- An agent with a teaching moment whose primary domain is in the focus list writes a full
  enrichment entry at the declared level (same behavior as unfocused).
- An agent with a teaching moment whose primary domain is outside the focus list evaluates
  whether the moment is genuinely load-bearing for understanding. If yes, it writes normally.
  If the moment is marginal — a secondary observation, a minor nuance, a cross-reference that
  could wait — it defers rather than produce a shallow entry that would not benefit from the
  learner's current attention.
- A cross-reference link pointing from an out-of-focus domain file to the relevant concept
  in an in-focus domain file is always written, even for marginal moments, because it costs
  little and preserves navigability.

This is a soft priority signal. The learner saying "this month I am studying concurrency"
intensifies teaching effort in `concurrency-and-async` without silencing the rest of the
knowledge base. Genuinely important teaching moments from any domain are never suppressed by focus.

---

## Relationship to the Enrichment Protocol

This Skill manages state. The enrichment protocol — what agents do with that state — is
defined in `learn/preamble.md`. Every learning-aware agent reads `preamble.md` on
session start when `enabled: true`. The Skill does not inline the protocol and does not
override it.

Cross-references:

- Enrichment contract: `learn/preamble.md`
- Domain taxonomy (authoritative list of 19 canonical domains): `docs/en/learn/domain-taxonomy.md`
- Architecture decision record (design): `docs/en/adr/001-developer-growth-mode.md`
- Architecture decision record (rename and relocation): `docs/en/adr/003-learning-mode-relocate-and-rename.md`
- Architecture decision record (coaching pillar): `docs/en/adr/004-coaching-pillar.md`
- Coach style files: `.claude/skills/learn/coach-styles/<style>.md`
- Per-agent domain ownership: each agent's `## Learning Domains` section in `.claude/agents/`
