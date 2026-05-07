## Issue mode

This sandbox was started to work a single GitHub issue. The issue body is at `ISSUE.md` in the repo root — read it first; it has the title, the source URL, the scope, the acceptance criteria, and the validation commands.

Workflow:

1. **Read** `ISSUE.md`. Note the title, the URL, the scope, and the acceptance criteria.
2. **Confirm understanding before coding.** Restate the goal, the in/out-of-scope split, and the acceptance criteria back to the user in 3-5 bullets. If anything is ambiguous or contradicts what you see in the repo, ask before writing code.
3. **Implement** the acceptance criteria. Stay in scope. If scope creep tempts you, surface it for the user to decide rather than silently expanding the change.
4. **Run the validation commands** listed in the issue's `## Validation` section before opening the PR. If the issue lists none, run the project's standard test/typecheck commands. Don't open a PR with unverified changes.
5. **Push the branch** with `git push -u origin HEAD` once validation passes. The sandbox is provisioned with a push-only deploy key and cannot open PRs or otherwise call the GitHub API. When the branch is pushed, stop and report the branch name to the human in this session — they will open the PR from the host.

Do not modify the source issue from inside this sandbox — no comments, no labels, no closes, no edits. The human runs that side.
