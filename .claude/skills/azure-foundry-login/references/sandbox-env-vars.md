# Updating `~/.sandbox/env` after a sandbox is created

This applies to any sandbox env var, not just Foundry — but it's most often hit when iterating on the Foundry env block (endpoint, model, project, deployment).

## How env injection works

`inject_env` (in `lib/sandbox-common.sh`) reads `~/.sandbox/env`, prefixes each `KEY=VALUE` line with `export `, and appends (`>>`) the result to `/etc/profile.d/sandbox-env.sh` inside the container. New login shells source that file, so they see the values.

Key implementation details:

- It **appends**, never rewrites. Stale entries persist until the file is wiped.
- `--env KEY=VALUE` flags get appended after the `~/.sandbox/env` contents, so they win when the same key is duplicated.

## Create path vs restart path (the quirk)

`sandbox-start` calls `inject_env` differently depending on whether the container is being created or restarted:

| Path | Trigger | Reads `~/.sandbox/env`? |
|---|---|---|
| Create | container doesn't exist | Yes, unconditionally |
| Restart | container is `STOPPED` | **Only if `--env` flags are passed** |

So a plain `sandbox-stop <name> && sandbox-start <name>` will *not* pick up edits to `~/.sandbox/env`. The fix is either to pass any `--env` flag (which re-runs `inject_env` and re-reads the file), or to fully recreate.

## Practical workflow

| Change | Cleanest action |
|---|---|
| Add a new var | `sandbox-stop <name> && sandbox-start <name> --env _NUDGE=1` (the `--env` triggers a re-read; the new var lands too) |
| Update an existing var's value | Same as above — later definitions in `/etc/profile.d/sandbox-env.sh` shadow earlier ones |
| Remove or rename a var | `sandbox-stop <name> --rm && sandbox-start <name> ...` — appends-only injection means stale lines stay otherwise |
| Quick hack inside a running container | Edit `/etc/profile.d/sandbox-env.sh` directly (`sudo` inside the sandbox), then open a fresh shell |

For the Foundry workflow specifically, you'll usually be reseeding tokens (`--copy-azure`) at the same time as tweaking the env block, so `sandbox-stop --rm && sandbox-start ... --copy-azure` is the mental model that always works.

## Why isn't this fixed?

Two reasons it's left as-is:

1. The append-only behavior is intentional for `--env` overrides — it lets ad-hoc flags override file values.
2. Re-reading `~/.sandbox/env` on every plain restart would silently change container behavior across reboots, which is surprising. Requiring an explicit `--env` (or recreate) keeps the trigger visible.
