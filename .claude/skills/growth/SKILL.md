---
name: growth
description: >
  Toggle Developer Growth Mode and manage per-domain focus for the living notebook at
  .claude/growth/notes/. Growth Mode is a default-off learning layer that instructs every
  growth-aware agent to contribute teaching moments to a domain-organized knowledge base as
  a by-product of normal work. When enabled, agents record explanations, trade-offs, and
  reasoning into per-domain Markdown files that accumulate over many sessions into a
  personalized reference the learner built by shipping real features.

  Supported invocations:
    /growth on [junior|mid|senior]   — Enable at the chosen level (default: stored level or junior)
    /growth off                      — Disable; preserve level and focus_domains for next enable
    /growth status                   — Print current config and last-ten notebook-diff summaries
    /growth focus <domain>[,<domain>] — Narrow agent teaching effort to one or more domains
    /growth unfocus                  — Clear focus_domains; agents treat all domains equally
    /growth level <junior|mid|senior> — Change level without toggling enabled state
    /growth domain new <key>         — Create a new custom domain file after learner confirmation
    /quiet                           — One-shot suppression of Growth enrichment for the current
                                       session only (separate Skill at .claude/skills/quiet/SKILL.md)

  This Skill is the only surface through which Growth Mode state changes. Agents read
  .claude/growth/config.json; they never write it. disable-model-invocation: true is
  non-negotiable — the learner, not the model, decides when to enter teaching mode.
disable-model-invocation: true
arguments:
  - name: action
    description: >
      on | off | status | focus | unfocus | level | domain
      Maps the first positional token after /growth.
  - name: level
    description: >
      Optional second positional token. Meaning depends on action:
        on      → junior | mid | senior (the level to enable at)
        focus   → comma-separated domain key list, or "clear"
        level   → junior | mid | senior (the level to set)
        domain  → "new <key>" (the subargument for new-domain creation)
---

# Growth Skill Reference

## Invariant

This Skill is the single and exclusive mechanism for changing Growth Mode state.
No agent reads any toggle signal other than `.claude/growth/config.json`. No agent
writes `config.json` directly — agents read it on session start and act on it, but
only this Skill writes it back. This boundary is enforced at the platform layer by
`disable-model-invocation: true`, which prevents the model from auto-invoking `/growth`
on the learner's behalf. The learner chooses to be taught; the model does not choose
to teach.

Why this matters: Growth Mode changes every subsequent agent turn in the session. It
causes agents to spend additional context reading domain files and writing enrichment.
That decision must originate from the learner explicitly, never from the model deciding
"this session seems educational."

**Do not remove `disable-model-invocation: true`** from this file's frontmatter. If
you do, the platform loses the enforcement boundary and a future model turn can silently
flip the learner into teaching mode. The regression test (see Implementation Notes in
ADR-001) asserts that this flag is present and set to `true`; removing it fails CI.

---

## Config Schema

Growth Mode state persists in `.claude/growth/config.json`. The schema is fixed; unknown
keys are preserved on write for forward compatibility.

```json
{
  "enabled": true,
  "level": "junior",
  "focus_domains": [],
  "updatedAt": "2026-04-22T00:00:00Z"
}
```

Field semantics:

- `enabled` — boolean, required. If absent or unparseable, treated as `false`. A parse
  error on the entire file is treated as disabled without surfacing an error to the learner.
- `level` — string, one of `"junior"`, `"mid"`, `"senior"`. Required when `enabled: true`.
  Preserved when `enabled` is set to `false` so the next `/growth on` restores the last
  level without the learner having to restate it.
- `focus_domains` — array of domain key strings; may be empty. When non-empty, agents with
  a teaching moment outside the listed domains evaluate whether the moment is genuinely
  load-bearing; if marginal, they defer rather than produce a shallow entry. Full enrichment
  is written for teaching moments in a focus domain. This is a soft priority signal, not a
  hard filter — genuinely important teaching moments are never suppressed because they fall
  outside the focus list.
- `updatedAt` — ISO 8601 timestamp; set by this Skill on every write. Agents do not update
  this field.

The file is created on first `/growth on` invocation. It does not exist in the repository
before first use. Both `config.json` and `.claude/growth/notes/` are gitignored by default;
see `.gitignore.example` for the opt-in inversion if you want to commit notes.

---

## Handler Logic by Action

### `on` — Enable Growth Mode

**Argument shape:** `$action=on`, `$level=<junior|mid|senior>` (optional)

Step-by-step:

1. Read `.claude/growth/config.json` if it exists.
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
Growth Mode enabled.
  Level: junior
  Focus: all domains (no focus set)
  Notebook: .claude/growth/notes/

Agents will contribute teaching moments to the domain-organized notebook as they work.
Run /growth status to see current state. Run /growth off to disable.
```

When a non-empty `focus_domains` is already in config, replace "all domains" with
the domain list, e.g. `Focus: architecture, testing-discipline`.

---

### `off` — Disable Growth Mode

**Argument shape:** `$action=off`

Step-by-step:

1. Read `.claude/growth/config.json` if it exists.
2. Write `config.json` with:
   - `"enabled": false`
   - All other fields preserved (`level`, `focus_domains`, `updatedAt` updated to now).
3. Print to the learner:

```
Growth Mode disabled.
  Level (preserved): junior
  Focus (preserved): all domains

Run /growth on to re-enable at the same level and focus.
```

The preserved state means the learner does not have to restate level and focus on the next
enable. `/growth on` alone restores the previous configuration.

---

### `status` — Display Current State

**Argument shape:** `$action=status`

This action never writes config.

Step-by-step:

1. Read `.claude/growth/config.json`. If absent, report disabled state.
2. Read the last-ten notebook-diff summaries from the learner's session history if available,
   or report "no recent diffs recorded" if the session has just started or the file does not
   exist. (Note: diff summaries are emitted as trailing sections in agent chat responses, not
   written to a file. The Skill reports the most recently visible ones in the current session
   context, or notes their absence if the session is new.)
3. Print a structured status block:

```
Growth Mode Status
──────────────────
Enabled:       true
Level:         junior
Focus domains: architecture, testing-discipline
Config path:   .claude/growth/config.json
Notes path:    .claude/growth/notes/
Last updated:  2026-04-22T14:30:00Z

Recent notebook diffs (last 10, most recent first):
  1. notes/architecture.md → add on `## Repository Pattern`: introduced repository pattern with
     first-principles explanation and worked example.
  2. notes/testing-discipline.md → deepen on `## The Invariant Ladder`: added caveat about E2E
     test flakiness in async frameworks.
  [... up to 10 entries ...]

Domain files present:
  .claude/growth/notes/architecture.md
  .claude/growth/notes/api-design.md
  [... one line per file that exists ...]

Run /growth on [junior|mid|senior] to change level.
Run /growth focus <domain> to narrow teaching effort.
Run /growth off to disable.
```

If config is absent or unparseable:

```
Growth Mode Status
──────────────────
Enabled:  false (no config file found)
Notes path: .claude/growth/notes/ (does not yet exist)

Run /growth on to enable. Default level: junior.
```

---

### `focus` — Set Focus Domains

**Argument shape:** `$action=focus`, `$level=<domain-csv>` or `$level=clear`

The second positional argument carries either a comma-separated list of domain keys or the
literal string `clear`.

**Clear focus** (`/growth focus clear` or `/growth unfocus`):

1. Read config.
2. Write config with `"focus_domains": []` and updated `updatedAt`.
3. Print:

```
Focus cleared. Agents will contribute teaching moments across all 19 canonical domains.
```

**Set focus** (`/growth focus <domain>[,<domain>]`):

1. Read config.
2. Parse the comma-separated domain key list from `$level`. Trim whitespace around each key.
3. Validate each key: it must exist as a `.md` file under `.claude/growth/notes/` (canonical
   or learner-opened custom domain). An unknown key that does not correspond to a file is an
   error. Print the error, do not write config. (The 19 canonical keys are always valid if the
   notes directory is seeded. Custom domains are valid only after the learner has created them
   via `/growth domain new <key>`.)
4. Write config with `"focus_domains": [<validated keys>]` and updated `updatedAt`.
5. Print:

```
Focus set: architecture, testing-discipline

Agents will write full enrichment entries for teaching moments in these domains.
Teaching moments in other domains are written only when genuinely load-bearing.
Run /growth unfocus to return to full-domain contribution.
```

---

### `unfocus` — Clear Focus (Alias)

**Argument shape:** `$action=unfocus`

Equivalent to `/growth focus clear`. Follows the same Clear focus step-by-step above.
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

Growth Mode remains enabled. Future agent contributions will use the senior angle:
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
   - Must not already exist as a file under `.claude/growth/notes/`.
   - Must not be one of the 19 canonical domain keys (those already exist).
   - Must be between 2 and 64 characters long.
   - If any validation fails, print a clear error describing the constraint, do not create
     any file, stop.
3. Print a confirmation prompt:

```
Create custom domain: <key>

This will create .claude/growth/notes/<key>.md with a seed placeholder. Agents will
be able to contribute teaching moments to this domain if their growth_domains include
it, but they will not auto-populate it until you explicitly work in this area.

This domain file is NOT an automatic fit for any existing agent's growth_domains.
To have an agent contribute here, you would need to add the key to that agent's
growth_domains frontmatter.

Confirm? [yes/no]
```

4. Wait for learner confirmation. If the learner responds with anything other than `yes`
   (case-insensitive), print "Cancelled. No file created." and stop.
5. On confirmation:
   a. Create `.claude/growth/notes/<key>.md` with seed content following the canonical shape:

```markdown
---
domain: <key>
last-updated: <YYYY-MM-DD>
contributing-agents: []
---

# <Title-Cased Key>

This is a custom domain opened by the learner. It covers concepts that do not fit
cleanly into the 19 canonical domains defined in docs/en/growth/domain-taxonomy.md.

Agents contribute here only when their growth_domains frontmatter includes this key.
The enrichment protocol is defined in .claude/growth/preamble.md.

## Placeholder

This section is seeded empty. The first agent with a teaching moment in this domain
will replace this placeholder with a real section following the enrichment protocol
in .claude/growth/preamble.md.
```

   b. Do not modify `focus_domains` in config unless the learner separately runs
      `/growth focus <key>`. Creating a domain does not automatically focus it.
   c. Print:

```
Created: .claude/growth/notes/<key>.md

The domain file is seeded and ready. It will be enriched by agents whose
growth_domains frontmatter includes "<key>". To narrow agent teaching effort to
this domain, run /growth focus <key>.
```

**Critical constraints for this action:**

- This Skill never writes pedagogical content into the new domain file beyond the seed
  placeholder. Knowledge content is agent territory; the Skill only creates the file
  structure. An agent writes the first real section when it encounters a teaching moment
  that belongs here.
- The Skill never modifies any existing file under `.claude/growth/notes/`. Notes are
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

Usage: /growth on [junior|mid|senior]
       /growth level [junior|mid|senior]
```

### Domain keys for `focus`

Domain keys passed to `/growth focus` must correspond to existing `.md` files under
`.claude/growth/notes/`. The 19 canonical keys are:

```
architecture          api-design           data-modeling
persistence-strategy  error-handling       testing-discipline
concurrency-and-async ecosystem-fluency    dependency-management
implementation-patterns review-taste       security-mindset
performance-intuition operational-awareness release-and-deployment
market-reasoning      business-modeling    documentation-craft
ui-ux-craft
```

Any learner-opened custom domain (created via `/growth domain new <key>`) is also valid
once its file exists.

Invalid domain key error:

```
Error: "<key>" is not a recognized domain. Valid keys are the 19 canonical domains
plus any custom domains you have created under .claude/growth/notes/.

Run /growth status to see which domain files are present.
```

### Unknown subcommand

If `$action` is not one of `on`, `off`, `status`, `focus`, `unfocus`, `level`, `domain`:

```
Unknown subcommand: "<action>"

Usage:
  /growth on [junior|mid|senior]       — Enable Growth Mode
  /growth off                          — Disable Growth Mode
  /growth status                       — Show current state
  /growth focus <domain>[,<domain>]    — Set focus domains
  /growth unfocus                      — Clear focus
  /growth level <junior|mid|senior>    — Change level
  /growth domain new <key>             — Create a custom domain

Growth Mode state: .claude/growth/config.json
Enrichment protocol: .claude/growth/preamble.md
Domain taxonomy: docs/en/growth/domain-taxonomy.md
```

Unknown subcommands do not halt the session. They print the usage message and return.

---

## `/quiet` — Per-Invocation Suppression

`/quiet` is a separate Skill at `.claude/skills/quiet/SKILL.md`. It is not a subcommand
of `/growth`.

Effect: suppresses the `## Growth: taught this session` and `## Growth: notebook diff`
trailing sections for the immediately following agent invocation. It does not disable
Growth Mode writes — the domain files are still updated. It only suppresses the visible
trailer in the chat response.

Detection: agents detect `/quiet` as a bare token in the current user turn's message.
No config file is written. The suppression applies to the one response being produced;
the next user turn restores normal trailer behavior automatically.

Authorship boundary distinction: `/growth` controls whether the notebook is maintained.
`/quiet` controls whether the session-contract trailer is rendered. These are orthogonal
decisions. A learner reading a long response in focused mode may not want the trailing
sections cluttering the output; that is a different decision from whether to continue
accumulating domain notes. Keeping them separate lets `/quiet` remain useful even outside
Growth Mode (e.g., suppressing other trailing sections in the future) without becoming a
grab-bag subcommand of `/growth`.

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

The notebook does not fork by level. A junior foundational entry from session one and a
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
notebook. Genuinely important teaching moments from any domain are never suppressed by focus.

---

## Relationship to the Enrichment Protocol

This Skill manages state. The enrichment protocol — what agents do with that state — is
defined in `.claude/growth/preamble.md`. Every growth-aware agent reads `preamble.md` on
session start when `enabled: true`. The Skill does not inline the protocol and does not
override it.

Cross-references:

- Enrichment contract: `.claude/growth/preamble.md`
- Domain taxonomy (authoritative list of 19 canonical domains): `docs/en/growth/domain-taxonomy.md`
- Architecture decision record: `docs/en/adr/001-developer-growth-mode.md`
- Per-agent domain ownership: each agent's `growth_domains:` frontmatter in `.claude/agents/`
