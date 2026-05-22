---
domain: ui-ux-craft
type: example
status: reference
fictional-project: "Meridian — B2B task-management SaaS (Go + Gin + PostgreSQL + Redis backend, React + TanStack Query + TypeScript frontend, Kubernetes + GitHub Actions deployment, per-seat subscription pricing)"
version: v2.2.0
owning-agent: ui-ux-designer
contributing-agents: [ui-ux-designer]
---

> **Read-only reference.** This file is shipped with the ECC Base Template as a worked
> example to illustrate what a populated knowledge file looks like after many sessions on
> a real project. It is **not** your knowledge file. Your own knowledge file lives at
> `.claude/learn/knowledge/ui-ux-craft.md` and starts empty until agents enrich it during real
> work. Agents never read, cite, or write under `.claude/meta/references/examples/` — this tree is
> for human readers only. See [ADR-003 §5](../adr/003-learning-mode-relocate-and-rename.md)
> for the design rationale.

---

## How to Read This File

Level markers indicate the intended audience for each section:
- `[JUNIOR]` — first-principles explanation; assumes no prior exposure
- `[MID]` — non-obvious idiomatic application in this stack
- `[SENIOR]` — non-default trade-off evaluation; names what is given up

---

## Information Density on the Task List  [JUNIOR] [MID] [SENIOR]

### First-Principles Explanation  [JUNIOR]

A list view is a scanning surface, not a reading surface. Users move down a task list
looking for a specific task or looking for tasks that demand attention. The critical
question for every field in a list row is: does this field help the user decide whether
to stop scanning? If the answer is no, the field has a cost — it consumes horizontal
space and draws the eye — without a benefit.

**Information density** describes how much data is visible per unit of screen area.
High density fits more data in fewer pixels. Low density gives each data point more
breathing room. Neither extreme is correct; the right density depends on what the user
is trying to do and how much data they are working with.

For a task management product, the task title is always worth displaying. The assignee
avatar is worth displaying when tasks are assigned to different people and the user needs
to know who owns what. The priority chip is worth displaying when priority is a sorting
signal, not decoration. Due date is worth displaying when time pressure is real.

The mistake is adding fields because they exist, not because they aid scanning. A row
that shows task title, assignee, priority, due date, project, labels, last comment
preview, and creation date is technically dense but practically unreadable: the user
cannot scan it because their eye does not know where to land.

### Idiomatic Variation  [MID]

Meridian's task list ships with two modes — Comfortable and Compact — added after
enterprise customer feedback. In Comfortable mode (the default), each row shows:

- Title (primary, large, truncated at one line)
- Assignee avatar (24 px, tooltip with full name)
- Priority chip (colored label: Urgent / High / Normal / Low)
- Due date (relative: "due tomorrow", "2 days overdue")

In Compact mode, the row height is reduced by 30% and the due date drops to an icon
with a tooltip. Assignee shrinks to 20 px. The title still gets the full remaining
width. The mode toggle is a workspace-level preference persisted per user, not a per-view
setting — a user who prefers Compact gets it everywhere.

The initial release shipped only Comfortable mode. The transition to offering both is
documented in [Prior Understanding: Single Density Mode](#prior-understanding-single-density-mode).

What the list deliberately omits: project name (accessible via hover on the title
breadcrumb), last-modified timestamp (available in the detail drawer), creation date
(available in the detail drawer), and labels (visible in the filter sidebar, not in rows
by default). Each omission was a deliberate choice: these fields are useful for deep
inspection but not for scanning.

### Trade-offs and Constraints  [SENIOR]

Adding a field to a list row costs scannability regardless of how compact the field is.
Every additional visual element creates one more thing the eye must learn to ignore when
it is irrelevant. The trade-off is always: does the presence of this field make the list
faster to use when the field matters, and can users tolerate its presence when it does
not matter?

The priority chip is the best example of this trade-off in Meridian. When all tasks have
Normal priority, the chip becomes visual noise — identical chips in every row. The design
team considered hiding the chip when priority is Normal (show only non-Normal priorities),
but analytics showed that users actively scan for Normal priority tasks when triaging, so
the chip was kept. The cost is visual uniformity when no triage is happening. The benefit
is consistent scannability during active triage sessions.

Compact mode is not a compromise — it is a different product for different users. Desktop
power users managing 200+ tasks per day benefit from Compact. Occasional users with small
lists benefit from Comfortable's breathing room. Shipping both modes costs maintenance
(two CSS layouts, two snapshot tests, two rows of E2E coverage) but serves the user
segment that drives Meridian's enterprise contracts.

See [See api-design → Cursor-Based Pagination on Task Lists](./api-design.md#cursor-based-pagination-on-task-lists)
for the API design that feeds this list view — specifically why cursor pagination was
chosen to avoid row-skipping artifacts when tasks are created during an active session.

### Prior Understanding: Single Density Mode

> Superseded: Meridian shipped v1.0 with a single row density. This was revised after
> enterprise customers with large workspaces reported that the list felt "sluggish to scan"
> compared to competitor tools.

**Prior implementation (single density):** One fixed row height, all four fields always
visible, no user preference.

**Corrected understanding:**

Enterprise users managing 200+ tasks do not have the same scanning needs as small-team
users with 15 tasks. A single density optimized for readability at small scale created
friction at large scale. The Compact mode was added in v1.4, gated behind a workspace
preference. The default remained Comfortable so existing users were not disrupted.

The lesson: density is not a universal preference. Products that cross the threshold
from small-team to enterprise use almost always need to offer multiple densities. The
forcing function is user complaints about scanning speed, not visual design instinct.

---

## Interaction States as First-Class Design  [JUNIOR] [MID]

### First-Principles Explanation  [JUNIOR]

Every interactive element in a user interface exists in multiple states. A button is not
just its default appearance — it also has hover, focus, active (pressed), disabled, and
loading states. A list row has default, hover, selected, and dragging states. A form field
has default, focused, filled, invalid, and disabled states.

Designing only the default state and leaving the rest to the browser or component library
produces interfaces that feel unfinished. When a user hovers a button and nothing happens,
they wonder whether the element is interactive. When a form field shows a red border after
submission but no message explaining why, the user does not know what to fix.

The discipline of **first-class interaction states** means treating every non-default state
as a design deliverable with the same specificity as the default state. Before shipping
any new surface, the designer (or the engineer reviewing the surface) runs through a
checklist: what does this look like when loading? When there is no data? When an error
occurs? When the user is not allowed to interact with it?

This is not perfectionism — it is the elimination of a class of bugs that are invisible
in tests but immediately visible to users.

### Idiomatic Variation  [MID]

Meridian uses the following surface checklist for every new component before it is
accepted in code review:

| State | Required for | What to define |
|-------|-------------|----------------|
| Default | All components | Resting appearance |
| Hover | Clickable, draggable elements | Cursor, background shift, or subtle lift |
| Focus | All interactive elements | Visible focus ring (3px, `--color-focus`) |
| Active (pressed) | Buttons, clickable rows | Brief scale-down (0.97) or darker fill |
| Disabled | Form controls, buttons | 40% opacity, `cursor: not-allowed`, tooltip explaining why |
| Loading | Data-dependent surfaces | Skeleton loaders, not spinners |
| Error | Forms, data fetching | Inline message at the source of the error |
| Empty | Lists, boards, search results | Illustrated empty state with a clear next action |

The focus ring requirement is non-negotiable: `outline: none` without a replacement focus
indicator is a WCAG 2.1 AA failure and a blocker in Meridian's code review. The ring uses
a design token (`--color-focus: oklch(68% 0.21 250)`) so it can be updated globally if the
accent color changes.

The loading state uses skeleton loaders (content-shaped gray blocks) rather than spinners
because Meridian's primary surface — the task list — has a known structure at load time.
A skeleton that mimics the task row shape tells the user what is loading and how much
space it will occupy. A spinner conveys only that something is happening. See
[See ecosystem-fluency → TanStack Query as Meridian's Data Layer](./ecosystem-fluency.md#tanstack-query-as-meridians-data-layer)
for how TanStack Query's `isLoading` and `isFetching` flags drive the skeleton display
and the distinction between initial load and background refresh.

The empty state is the most commonly omitted state. In Meridian, every list view has a
designed empty state: an illustration, a headline ("No tasks yet"), and a primary action
("Create your first task"). The illustration is surface-specific — the task list, the
team board, and the notification center each have their own. Empty states are not bolted
on; they are designed in the same pass as the populated state.

### Trade-offs and Constraints  [SENIOR]

Designing all eight states takes time. The trade-off is front-loaded cost against
back-loaded defects. A missing disabled state is discovered in user testing or support
tickets, not in unit tests. A missing empty state means the first user to reach that
state sees a blank page with no guidance — a high-friction moment that often triggers a
support ticket or a churn signal.

The skeleton-over-spinner choice has a maintenance cost: skeletons must be updated when
the layout of the surface changes. A spinner never goes stale. In Meridian, this cost is
accepted because the user experience benefit is significant: the task list skeleton renders
in the same visual rhythm as the populated list, which reduces perceived load time by
giving the user orientation before data arrives.

The disabled state tooltip is a specific investment. Rather than leaving disabled buttons
unexplained, Meridian shows a tooltip on hover explaining why ("Only workspace admins can
archive a workspace"). This is a microcopy commitment — every disabled state must have a
reason, and that reason must be written. The cost is authoring time. The benefit is that
users understand what they cannot do and why, which reduces confusion and support load.
See [See documentation-craft.md](./documentation-craft.md) for the microcopy discipline
that governs these explanations.

---

## Accessibility: Keyboard Navigation and Contrast  [MID] [SENIOR]

### Idiomatic Variation  [MID]

Meridian's kanban board presents a drag-and-drop interface for moving tasks between status
columns. Drag-and-drop is inherently pointer-dependent: the interaction model requires a
pointing device to initiate a drag. For keyboard and screen-reader users, this is a
complete blocker without an explicit alternative.

The alternative Meridian ships is a context menu on every task card, accessible via the
keyboard shortcut `Enter` or the three-dot button (visible on focus and hover). The menu
includes "Move to..." actions for each column. The action is keyboard-operable, announced
by screen readers, and produces the same result as a drag-and-drop.

The keyboard flow for moving a task to "Done" without a pointer: `Tab` to the task card,
`Enter` to open the context menu, arrow keys to "Move to..." then "Done", `Enter` to
confirm.

The board also supports arrow key navigation between cards within a column (`Up`/`Down`)
and between columns (`Left`/`Right`). The current card receives a visible focus ring.
`aria-live="polite"` announces column changes when a task is moved: "Task 'Update billing
contact' moved to Done."

### Trade-offs and Constraints  [SENIOR]

The keyboard alternative is not as fast as drag-and-drop for power users with a pointer.
This is the expected trade-off: accessibility alternatives rarely match the speed of their
pointer equivalents. The goal is not identical speed; it is equivalent capability. A
keyboard user can perform every action a pointer user can perform; the path is longer but
complete.

The priority chip contrast ratio required a specific design decision. The initial design
used fully saturated chip backgrounds: bright red for Urgent, bright orange for High,
muted green for Normal, gray for Low. Under WCAG 2.1 AA, text on a colored background
requires a 4.5:1 contrast ratio for small text (below 18px bold or 24px regular). The
bright red background (`oklch(55% 0.21 25)`) against white text passed at 4.8:1.
The bright orange background (`oklch(68% 0.18 55)`) against white text failed at 2.9:1.

The corrected design uses darker chip backgrounds for High priority:
`oklch(48% 0.18 55)` (dark amber), which passes at 4.6:1 against white. The visual cost
is that the High chip no longer looks "bright orange" — it reads as dark amber, which is
less immediately alarming than the original color. The design team accepted this trade-off:
WCAG AA compliance is non-negotiable for a B2B product that may be used by customers
with accessibility requirements written into their procurement contracts.

Enterprise procurement for B2B SaaS increasingly includes accessibility requirements as
contract terms; a product that cannot demonstrate WCAG AA compliance may be disqualified
at the vendor evaluation stage. See [See business-modeling.md](./business-modeling.md)
for how per-seat enterprise contracts drive design decisions like this one.

---

## Microcopy: Precision at Decision Points  [JUNIOR] [MID]

### First-Principles Explanation  [JUNIOR]

**Microcopy** is the short text in a user interface: button labels, confirmation messages,
error explanations, empty state headlines, placeholder text, tooltip content. It is called
"micro" because each piece is small — a few words, rarely more than two sentences. Its
cumulative effect on usability is large.

The most common microcopy failure is ambiguity at decision points. A modal that says:

> Are you sure?
> **Cancel** | **OK**

puts two words in front of the user that do not answer the question "what happens if I
click OK?" The user must remember what action triggered the modal in order to interpret
what "OK" means. If the action was "archive this task," the user must recall that "OK"
means "yes, archive it." This is recall instead of recognition — a violation of one of
Nielsen's usability heuristics.

Precise microcopy answers the question directly:

> Archive "Update billing contact"?
> This task will be moved to the archive. You can restore it later.
> **Keep editing** | **Archive task**

The primary action ("Archive task") names the action. The secondary action ("Keep
editing") names what the user is keeping, not what they are canceling. The user does not
need to recall context: the modal carries the context itself.

### Idiomatic Variation  [MID]

Meridian uses two distinct confirmation patterns based on the reversibility of the action.

**Reversible destructive actions** (archive, close, unassign): A modal with a description
of the action and the consequence, with labeled primary and secondary buttons. The
secondary button is always "Keep [noun]" rather than "Cancel" — the user is not canceling
a request; they are choosing to keep the current state.

Examples from the Meridian codebase:
- Archiving a task: "Archive task" / "Keep editing"
- Closing a project: "Close project" / "Keep open"
- Removing an assignee: "Remove [Name]" / "Keep assigned"

**Irreversible destructive actions** (delete, permanently remove): A typed-confirmation
modal. The user must type the resource name or the word "delete" before the primary button
enables. The primary button is red and labeled with the exact action: "Delete workspace",
not "Delete" or "Confirm".

The typed-confirmation pattern appears only for irreversible actions. Meridian's rule:
if the action can be undone (restored from archive, re-invited, re-opened), use a standard
confirmation modal. If the action cannot be undone, require typed confirmation. This
distinction is important because requiring typed confirmation for every destructive action
would train users to type quickly without reading, defeating the purpose.

The "Don't save" anti-pattern: when a user has unsaved changes and navigates away, the
modal should not read "Cancel" / "Don't save" — "Don't save" is a double negative that
slows interpretation. Meridian uses "Keep editing" / "Discard changes": both affirmative,
naming what the button does rather than negating another action.

### Trade-offs and Constraints  [SENIOR]

Precise microcopy requires knowing the resource name at confirmation time. "Archive task"
is more useful than "Archive item" because the user knows exactly what they are acting on.
But this requires the modal to receive the task title as a prop (or to read it from context)
rather than being a generic confirmation component that any surface can call.

In Meridian, the design decision was to make every confirmation modal resource-aware. The
cost is that the generic `<ConfirmationModal>` component does not exist; there is an
`<ArchiveTaskModal>`, a `<DeleteWorkspaceModal>`, and so on. Each knows its resource. This
is more code than a single generic modal, but the user experience benefit — precise,
context-carrying language in every confirmation — is worth the duplication.

The alternative — a generic modal with a resource name prop — is possible but fragile.
String interpolation in button labels ("Archive [task name]") works for English but breaks
in gendered languages where the article and verb form depend on the noun. Meridian does not
yet ship non-English locales, so this is a deferred concern. If localization is added,
the resource-specific modal approach will require a localization wrapper per modal rather
than a single translated string template. That is a known cost of the current approach.

---

## Dark Mode as a Design System Commitment  [MID] [SENIOR]

### Idiomatic Variation  [MID]

Dark mode in Meridian is not a CSS `prefers-color-scheme` media query applied to a single
color variable. It is a dual-palette design system: every color in the system has both a
light-mode and a dark-mode value, and the values are not simply inverted.

The design token structure:

```css
:root {
  /* Semantic tokens — always reference these, never raw palette */
  --color-surface-primary: oklch(98% 0 0);
  --color-surface-secondary: oklch(94% 0 0);
  --color-text-primary: oklch(14% 0 0);
  --color-text-secondary: oklch(42% 0 0);
  --color-border: oklch(88% 0 0);
  --color-accent: oklch(55% 0.21 250);
  --color-focus: oklch(68% 0.21 250);
  --color-urgent: oklch(48% 0.21 25);
  --color-high: oklch(48% 0.18 55);
}

[data-theme="dark"] {
  --color-surface-primary: oklch(16% 0 0);
  --color-surface-secondary: oklch(22% 0 0);
  --color-text-primary: oklch(94% 0 0);
  --color-text-secondary: oklch(68% 0 0);
  --color-border: oklch(30% 0 0);
  --color-accent: oklch(70% 0.21 250);   /* lighter in dark mode */
  --color-focus: oklch(78% 0.21 250);    /* lighter in dark mode */
  --color-urgent: oklch(62% 0.21 25);    /* lighter in dark mode */
  --color-high: oklch(62% 0.18 55);      /* lighter in dark mode */
}
```

The key insight: the semantic tokens (surface, text, border) are named for their function,
not their color value. Components reference `--color-surface-primary`, never a raw hex or
`oklch()` call. When the theme changes, every component that uses semantic tokens
recolors automatically without a code change.

The accent, urgent, and high colors change in dark mode because the contrast requirement
inverts. In light mode, the urgent color must be dark enough for white text to read at
4.5:1 on it. In dark mode, the surface is dark, so the urgent color can be lighter — the
text on the chip is still white or dark depending on the chip's lightness. The dual-palette
approach handles this correctly; a simple CSS inversion (`hue-rotate(180deg)` or flipping
lightness) does not.

### Trade-offs and Constraints  [SENIOR]

The cost of a real dual-palette dark mode is that every new color introduction requires
two decisions: the light value and the dark value. Engineers who add a one-off inline
color break the system. Meridian enforces this through a stylelint rule that flags raw
`oklch()`, `rgb()`, and hex values outside the tokens file. The rule is not airtight
(CSS custom properties can be set via JavaScript), but it catches the most common drift.

The alternative — a CSS `prefers-color-scheme` inversion — ships faster and requires zero
ongoing discipline. The trade-off is that inversions rarely look right: shadows become
light glows, colorful chips designed for a white background look wrong on near-black
surfaces, and teams that ship inversion-based dark mode consistently receive user reports
that dark mode is unusable.

Dark mode is either a first-class design system commitment or it is a liability. A partial
dark mode — where most surfaces look correct but some clearly do not — is worse than no
dark mode, because it signals to users that the product is broken in the mode they have
enabled. Meridian made the commitment in v1.2, after analytics showed 34% of active users
had dark mode enabled at the OS level. The delay was a resource decision; the commitment,
once made, was total.

---

## The Assignment Modal: Surface-Driven Disclosure  [MID] [SENIOR]

### Idiomatic Variation  [MID]

The task assignment modal is the surface where users assign a task to a team member,
set a due date, and adjust priority. The original design showed all three fields in the
modal simultaneously, each fully editable. In user testing, participants hesitated before
interacting with the modal: seeing three editable fields at once created the impression
that all three needed to be filled before the assignment could be saved.

The revised design applies **progressive disclosure**: the modal opens with the assignee
field in focus, and the due date and priority fields are below the fold with a subtle
divider. The primary action button reads "Assign" (not "Save" or "Update"), which
communicates the purpose of the modal's primary outcome. Users who want to also adjust
due date or priority scroll to those fields; users who only want to assign can complete
the modal with one click after selecting a team member.

This is not hiding fields — all three fields are present and accessible. It is
sequencing emphasis: the assignee field is the modal's primary concern, and the UI
communicates that by giving it the most visual weight and keyboard focus on open.

The "right thing is editable" principle: a field should be editable in the assignment
modal if a user commonly wants to change it at the moment of assignment. Due date and
priority pass this test. The task title does not — users do not rename tasks while
assigning them, and having the title editable in the assignment modal created accidental
edits in user testing. The title field in the modal is read-only with a link to the
detail view.

### Trade-offs and Constraints  [SENIOR]

Progressive disclosure means some users will not discover the due date and priority fields
if they do not scroll. The trade-off is discoverability against cognitive load. Meridian
accepted this trade-off because the assignment modal is used at high frequency (multiple
times per work session for active users), which means users learn the modal's structure
quickly. A modal used rarely benefits more from immediate disclosure (all fields visible);
a modal used frequently benefits more from a focused primary action.

The "Assign" button label is a specific choice. Alternatives — "Save", "Update", "Done",
"Confirm" — are all generic. "Assign" names the action. The cost of specific labels is
that they must change if the modal's purpose changes (e.g., if the modal is repurposed
to also support unassignment in a future version, "Assign" becomes ambiguous). That is a
maintenance commitment: the button label must be updated whenever the action changes.
Generic labels degrade less over time; specific labels communicate better in the moment.

See [See architecture → Cross-Cutting Concern: Notifications](./architecture.md#cross-cutting-concern-notifications)
for how the backend handles the notification triggered when the user clicks "Assign" —
specifically the best-effort notification pattern where a Slack notification failure does
not fail the assignment action.

### Coach Illustration (default vs. hints)

> **Illustrative only.** The following is a worked example of how the two coaching styles
> differ for a task in this domain. It is not part of the live agent contract. Actual
> agent behavior is governed by the style files at
> `.claude/skills/learn/coach-styles/`.

**Scenario:** A learner asks the agent to design the task assignment modal for Meridian —
specifically to determine which fields to show, in what order, and what the primary action
button should say.

**`default` style** — The agent produces the full specification: the component hierarchy
(`<AssignmentModal>` with `<AssigneeField>` in primary position, a divider, and
`<SecondaryFields>` containing `<DueDateField>` and `<PriorityField>`), the interaction
state for each field, the primary button label rationale ("Assign" rather than "Save"),
and the keyboard flow (Tab through fields; Enter to confirm). `## Learning:` trailers
explain the progressive disclosure principle and the microcopy rationale.

**`hints` style** — The agent names the pattern (progressive disclosure), identifies the
primary action (assigning a user), and emits:

```
## Coach: hint
Step: Define the modal's primary concern — which single action does the user open this
      modal to perform?
Pattern: Progressive disclosure — surface the primary action at modal-open; secondary
         fields are accessible but not competing for focus.
Rationale: Showing all fields at equal visual weight creates the impression that all
           fields are required, which increases task completion time and hesitation.
```

`<!-- coach:hints stop -->`

The learner identifies the primary action and field ordering. On the next turn, the agent
helps specify interaction states for each field.
