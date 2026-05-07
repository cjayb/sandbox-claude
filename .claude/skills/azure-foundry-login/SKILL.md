---
name: azure-foundry-login
description: Authenticate Claude Code in a sandbox container against Azure AI Foundry using the host user's AAD identity (RBAC, no ANTHROPIC_FOUNDRY_API_KEY). Covers both the in-container `az login --use-device-code` flow and the `sandbox-start --copy-azure` token-seeding fallback for tenants where Conditional Access blocks device-code. Use whenever a sandbox is created from the python stack and Claude Code must route through Foundry.
---

# Azure Foundry Login (sandbox containers)

Routes `sandbox <name> --claude` through Azure AI Foundry using the host user's AAD identity instead of an `ANTHROPIC_FOUNDRY_API_KEY`.

Two auth paths, in order of preference:

1. **`az login --use-device-code` inside the container** — clean isolation, but many enterprise tenants block device-code via Conditional Access ("doesn't meet the criteria to access this resource"). Try this first.
2. **`sandbox-start --copy-azure`** — copies the host's `~/.azure/` into the container at create time so the existing host login is reused. Use this when device-code is blocked. A true bind mount would need idmapped-mount kernel support (OrbStack lacks it) or `raw.idmap` (breaks incus's systemd-credentials mount), so we copy instead. Tradeoff: token rotations don't sync between host and container — recreate the sandbox after refresh-token expiry.

## What ships with the sandbox

The base golden image installs the Azure CLI (`stacks/base.sh`), so every stack has `az` available:

```bash
curl -sL https://aka.ms/InstallAzureCLIDeb | bash
```

The default domain allowlist (`domains/anthropic-default.txt`) includes the four endpoints the device-code flow and Foundry calls require:

| Domain | Purpose |
|---|---|
| `.microsoftonline.com` | OAuth/AAD token endpoint |
| `login.microsoft.com` | Device-code flow |
| `management.azure.com` | ARM (subscriptions, resource lookups) |
| `.services.ai.azure.com` | Foundry inference endpoints |

These are HTTPS, so default egress already permits them. They only matter when `--restrict-domains` is set.

## End-to-end sequence (device-code path)

1. Ensure the golden image is current — rebuild if `python.sh` changed:
   ```bash
   sandbox-setup --rebuild python
   ```
2. Put the Foundry env block in `~/.sandbox/env` (no `export` prefix; one `KEY=VALUE` per line).
3. Start the sandbox:
   ```bash
   sandbox-start <name> <git-url> --stack python
   ```
4. Open a shell and authenticate:
   ```bash
   sandbox <name>
   az login --use-device-code
   ```
   Open `https://microsoft.com/devicelogin` on the host, paste the code.
5. Verify and launch (see "Verify and launch" below).

If step 4 fails with *"You don't have access to this... browser, app, location, or authentication flow that is restricted by your admin"*, device-code is blocked by Conditional Access. Switch to the bind-mount path.

## End-to-end sequence (token-seeding path)

Use when device-code is blocked. Run `az login` once on the host (browser-based, satisfies CA), then start sandboxes with `--copy-azure`:

1. On the host:
   ```bash
   az login
   az account show   # confirm tenant/subscription
   ```
2. Start the sandbox with the host's `~/.azure/` copied in:
   ```bash
   sandbox-start <name> <git-url> --stack python --copy-azure
   ```
3. Verify and launch (see below). No `az login` needed inside the container.

`--copy-azure` only seeds tokens once at create time. The container's copy diverges from the host as either side refreshes. When the container's refresh token rotates or expires, recreate the sandbox (`sandbox-stop <name> --rm` then `sandbox-start ...`).

## Verify and launch

```bash
sandbox <name>
az account show
az cognitiveservices account list
sandbox <name> --claude
```

## Token persistence

- **Device-code path**: `~/.azure/` lives on the container's filesystem — survives `sandbox-stop` / `sandbox-start`. Re-login required after `sandbox-stop --rm`, `sandbox-nuke`, or refresh-token expiry. Each parallel sandbox needs its own `az login`.
- **Token-seeding path (`--copy-azure`)**: each container gets its own copy of `~/.azure/` at create time. Tokens persist inside the container across `sandbox-stop`/`sandbox-start`, but rotations don't sync between host and container. When the container's refresh token expires, refresh per the section below.

## How token refresh works

Three layers, easy to conflate:

1. **Access token** (~1 hour). Bearer JWT used for actual API calls. The CLI mints these silently from the refresh token whenever you make an `az` call. You don't see this happening.
2. **Refresh token** (default ~90 days, tenant policies may shorten). Used to mint access tokens. Silent refresh hits `login.microsoftonline.com` but does *not* trigger device-code or interactive prompts, so Conditional Access usually doesn't bite.
3. **Cache file** (`~/.azure/msal_token_cache.json`). Where both live on disk.

Day-to-day, you do nothing — silent refresh just works inside the container as long as `login.microsoftonline.com` is reachable.

### Switching subscription (no re-auth needed)

`az account set --subscription <name-or-id>` works inside the container with no re-auth, as long as the target sub was visible to the host login that seeded `~/.azure/azureProfile.json`. The access token is bound to your AAD identity, not a subscription. If you need a subscription that wasn't on the host, re-login on the host first and reseed.

### When silent refresh actually fails

You'll see `AADSTS700xx` errors from `az` (most common: `AADSTS70008` "refresh token has expired"). The refresh token is dead and needs replacing. Two ways to recover:

**Easiest — recreate the sandbox** (gets a fresh full copy of `~/.azure/`):

```bash
# on the host
az login

sandbox-stop <name> --rm
sandbox-start <name> <git-url> --stack python --copy-azure
```

**Faster — patch just the token cache into the running container**:

```bash
# on the host
az login

orb run -m sandbox sudo incus file push \
  ~/.azure/msal_token_cache.json ~/.azure/azureProfile.json \
  agent-<name>/home/ubuntu/.azure/ \
  --uid=1000 --gid=1000
```

(On Linux, drop `orb run -m sandbox` and run `sudo incus file push ...` directly.)

### Divergence caveat

If either side rotates a refresh token (AAD does this periodically), the other side's cached refresh token may get invalidated server-side — silent refresh on the stale side will start failing with `AADSTS70008` and you'll need to reseed. In practice this is rare day-to-day, but it's the reason `--copy-azure` is a snapshot, not a sync.

## Updating the Foundry env block after creation

Editing `~/.sandbox/env` after a sandbox already exists has a subtle quirk: a plain `sandbox-stop && sandbox-start` does *not* re-read the file. See [`references/sandbox-env-vars.md`](references/sandbox-env-vars.md) for the create-vs-restart behavior, the practical workarounds, and why it isn't auto-fixed.

Short version: when iterating on Foundry env vars, recreate with `sandbox-stop <name> --rm && sandbox-start <name> ... --copy-azure`. That's the mental model that always works.

## Restricted-domain mode

If `--restrict-domains` is enabled, the four Azure domains above are already in `domains/anthropic-default.txt`. For a project-specific allowlist (`~/.sandbox/allowed-domains.txt`), add them explicitly:

```
login.microsoft.com
.microsoftonline.com
management.azure.com
.services.ai.azure.com
```
