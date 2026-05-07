## Issue mode

This sandbox was started to work a single GitHub issue. The issue body is at `ISSUE.md` in the repo root — read it first; it has the title, the source URL, the scope, the acceptance criteria, and the validation commands.

Workflow:

1. **Read** `ISSUE.md`. Note the title, the URL, the scope, and the acceptance criteria.
2. **Confirm understanding before coding.** Restate the goal, the in/out-of-scope split, and the acceptance criteria back to the user in 3-5 bullets. If anything is ambiguous or contradicts what you see in the repo, ask before writing code.
3. **Implement** the acceptance criteria. Stay in scope. If scope creep tempts you, surface it for the user to decide rather than silently expanding the change.
4. **Run the validation commands** listed in the issue's `## Validation` section before opening the PR. If the issue lists none, run the project's standard test/typecheck commands. Don't open a PR with unverified changes.
5. **Open the PR with `gh pr create`** when validation passes. The PR title follows the repo's commit format (e.g. `feat: …`, `fix: …`). The PR body must include `Closes #<num>` (or `Fixes #<num>`) using the issue number from `ISSUE.md` so GitHub links the PR back to the issue.

Do not modify the source issue from inside this sandbox — no comments, no labels, no closes, no edits. The human runs that side.
