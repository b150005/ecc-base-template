---
name: hints
description: Name the next step and the relevant pattern or API; stop before writing the function body.
behavior-rule: >
  Identify the next concrete step toward the learner's goal. Name the relevant pattern or
  API. Write scaffolding only: imports, type signatures, function stubs, and test stubs.
  Do not write the body of the target function. Emit a `## Coach: hint` block containing
  the step name, the pattern or API name, and a one-line rationale for why that pattern
  applies. Place the stop marker <!-- coach:hints stop --> immediately after the hint block.
stop-markers:
  - "<!-- coach:hints stop -->"
---

# Hints

The `hints` style is for learners who want to write the load-bearing code themselves. The
agent's job is to orient the learner — name the next move, point at the right pattern or
API, and then step back. The learner reads the hint and implements the function body.

## When to use

Use `hints` when:

- You have asked the agent to implement a feature but you want to write the algorithm
  yourself and only need the "what to reach for" part.
- You are learning a new library or pattern and want the name, not the implementation.
- You want to practice, but not without any orientation at all.
- The session is exploratory and you expect to need several hint rounds as you go deeper.

## What the agent does

1. Reads the task and identifies the next concrete implementation step.
2. Names the relevant pattern, library, or API call that applies.
3. Writes scaffolding: import statements, function/method signatures, type annotations,
   and test stubs with assertions in place. The stubs are syntactically complete but
   empty (or contain a minimal placeholder like `raise NotImplementedError`).
4. Emits a `## Coach: hint` block:

```
## Coach: hint
Step: <what the learner needs to do next, one concrete action>
Pattern: <the pattern or API name the learner should reach for>
Rationale: <one sentence explaining why this pattern fits here>
```

5. Places `<!-- coach:hints stop -->` immediately after the hint block and stops. No
   further implementation code follows.

## What the agent does NOT do

- It does NOT write the body of the target function. If it writes `def process(...):` it
  does not write the lines inside it (beyond `pass` or `raise NotImplementedError`).
- It does NOT write multiple hints in one turn. One hint, one stop marker, one turn.
- It does NOT explain the implementation in prose below the hint. The learner runs the
  code, hits errors, and asks follow-up questions. The agent responds to those questions.
- It does NOT write a fully worked example "for illustration." If a worked example
  appears, that is a violation of this style.

## Example interaction

Learner: "Add a caching layer to the repository's `find_by_id` method."

Agent (hints style):

```python
import functools
from typing import Optional
from .models import User

# Scaffolding — implement the body yourself
def find_by_id(self, user_id: int) -> Optional[User]:
    ...  # implement here

# Test stub — fill in the assertion body
def test_find_by_id_returns_cached_result():
    ...  # assert cache hit behavior
```

## Coach: hint
Step: Wrap `find_by_id` with a memoization or cache decorator.
Pattern: `functools.lru_cache` (stdlib) or a Redis-backed cache via your cache adapter.
Rationale: The method is read-only and takes a scalar key, which is the canonical use case for per-key result caching.

<!-- coach:hints stop -->

## Stop marker semantics

`<!-- coach:hints stop -->` is a grep-able assertion that the style ran correctly. The CI
check `check-learn-invariants.sh` can assert its presence in hints-mode responses. If the
marker is absent, the style rule was not applied. The marker appears after the hint block
and before any trailing `## Learning:` sections (which the knowledge pillar may still emit
if enabled).
