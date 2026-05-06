# Sandbox Container Conventions

You are running inside an isolated sandbox container. The host filesystem and credentials are not reachable. Code lives at `/workspace/project` and round-trips to the host via `git push` / `git fetch`.

## Philosophy

- **Simplicity is king** — the simplest solution that works is the best solution
- **Self-documenting code** — if it needs comments, refactor it
- **Functional over OOP** — pure functions, composition, immutability
- **Commit early, commit often** — small, focused, verified commits

## Cross-Language Design Principles

These rules apply to all languages, regardless of tooling.

### Code Design
- Prefer pure functions where feasible; isolate side effects.
- Organize code so changes are easy and predictable.
- Avoid hidden state and mutable globals.

### Types & Data
- Declare types explicitly at *module boundaries*.
- Use language-specific type features to model domain constraints (e.g. Rust enums, TS `zod` schemas, Python TypedDict / dataclasses).

### Error Handling
- Treat errors as structured data, not control flow.
- Catch specific exceptions, never bare `except:` or `except Exception:` unless re-raising.
- Add contextual information when propagating errors.
- Avoid swallowing errors silently.
- Let unexpected errors crash — they reveal bugs. Only catch what you can handle.

### Testing
- Prefer unit tests for pure logic and integration tests for I/O boundaries.
- Assert behavior, not implementation details.
- Aim for reproducibility and determinism.
- Use AAA pattern (Arrange, Act, Assert).

### Comments & Docs
- Use comments to explain *why*, never *what* — if you need a "what" comment, rename or refactor instead.
- Bad: `timeout = 30  # API timeout in seconds`
- Good: `API_TIMEOUT_SECONDS = 30`
- Public APIs must have documentation; internal helper functions usually do not.
- If code needs lots of comments, refactor instead.

### Architecture & Boundaries
- Divide code into layers (core logic, side effects, interfaces).
- Keep modules small and focused.
- Separate business logic from runtime and framework concerns.

## Git

### Branching

Before making changes, check the current branch. If it is `main` or `master`, pull latest from the remote and check out a new branch first. Never commit directly to main.

### Commit format

```
type: short description
```

| Type | Use |
|------|-----|
| `feat:` | New feature |
| `fix:` | Bug fix |
| `docs:` | Documentation |
| `chore:` | Maintenance |
| `refactor:` | Restructure (no behavior change) |
| `test:` | Tests |

### Pull requests

- Title: same format as commits (`type: description`)
- Description: explain the *why*, not just the *what*
- Before/after: show output changes when relevant
- Link related issues
- Keep PRs focused — one logical change per PR

### Pushing from this container

The container is provisioned with a single deploy key (or your forwarded SSH key) scoped to one repo. `git push` works out of the box for that repo only. If you need to push elsewhere, stop and ask the user — silently rewriting remotes is the wrong move.

---

**The Loop:** Change → Verify → Commit → Repeat. If it's not tested, it's not done.
