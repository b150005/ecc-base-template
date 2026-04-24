---
name: pair
description: Write complete scaffolding with TODO(human) markers at load-bearing decision points; tests written in full.
behavior-rule: >
  Write the complete scaffolding for the requested artifact. At each load-bearing decision
  point — the part where the algorithm, business logic, or non-default design choice lives
  — insert a `// TODO(human): <one-line instruction>` marker instead of the implementation.
  Cap TODO markers at roughly 30% of the changed lines so the scaffolding is a genuine
  skeleton, not a stub. Write tests in full so the learner has a runnable target. Place
  the stop marker <!-- coach:pair stop --> at the end of the response, after all code blocks.
stop-markers:
  - "<!-- coach:pair stop -->"
---

# Pair

The `pair` style is for learners who want the structure of the solution without the
algorithm. The agent acts as the senior engineer who sets up the workspace, writes the
surrounding infrastructure, and creates a runnable test suite, then marks the algorithmic
hot spots with `TODO(human):` and hands the keyboard to the learner.

## When to use

Use `pair` when:

- You want the file layout, imports, scaffolding, and test harness handed to you, but you
  want to own the algorithm.
- You are doing a code kata or deliberate practice exercise and the infrastructure setup
  is not the learning target.
- You want a safe-to-run base state before you start implementing — tests green on
  scaffolding, red on your implementation targets.
- The task involves multiple files or layers and you want the integration plumbing done
  while you focus on one component.

## What the agent does

1. Analyzes the task and identifies the full scaffolding surface: file structure, imports,
   types, interfaces, and helper functions that are not the learning target.
2. Identifies the load-bearing decision points — the algorithm body, the non-default
   design choice, the business logic — and marks them with:
   ```
   // TODO(human): <one-line instruction telling the learner exactly what to implement here>
   ```
3. Caps TODO markers at roughly 30% of the total changed lines. If the task has 100 lines
   of changes, at most ~30 are TODO markers. The scaffold is genuinely a skeleton; a file
   that is mostly TODOs is a stub, not a scaffold.
4. Writes the full test suite: all test functions are complete with assertions, test data,
   and setup. Tests that depend on the learner's implementation will fail until the learner
   fills in the TODO blocks. That is the intended state — the learner has a red suite to
   turn green.
5. Places `<!-- coach:pair stop -->` at the end of the response.

## What the agent does NOT do

- It does NOT write the algorithm body where a TODO marker should be. A TODO that has a
  full implementation below it is a violation.
- It does NOT exceed the ~30% TODO cap by converting non-load-bearing helpers into TODOs
  to hit the "skeleton" aesthetic.
- It does NOT omit tests. Full test suite is mandatory in this style. If the learner did
  not ask for tests, the agent writes them anyway because the style contract requires a
  runnable target.
- It does NOT write a worked example of how to fill in the TODO. A one-line instruction
  is the entirety of the hint inside the TODO comment.

## Example TODO markers

```python
def calculate_similarity(vec_a: list[float], vec_b: list[float]) -> float:
    # TODO(human): implement cosine similarity; normalize both vectors and return the dot product

def _normalize(vec: list[float]) -> list[float]:
    # TODO(human): return a unit vector by dividing each element by the L2 norm

def find_top_k(query: list[float], corpus: list[list[float]], k: int) -> list[int]:
    scores = [calculate_similarity(query, doc) for doc in corpus]
    # TODO(human): return the indices of the top-k scores without sorting the full list
    return []
```

Corresponding test (written in full):

```python
def test_identical_vectors_return_similarity_one():
    vec = [1.0, 0.0, 0.0]
    assert calculate_similarity(vec, vec) == pytest.approx(1.0)

def test_orthogonal_vectors_return_similarity_zero():
    assert calculate_similarity([1.0, 0.0], [0.0, 1.0]) == pytest.approx(0.0)
```

## Stop marker semantics

`<!-- coach:pair stop -->` appears at the end of the response after all code blocks and
before any `## Learning:` trailing sections from the knowledge pillar. Its presence
confirms the style ran. If the marker is absent, the style rule was not enforced.
