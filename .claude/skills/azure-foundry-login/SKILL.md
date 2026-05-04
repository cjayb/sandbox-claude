---
name: azure-foundry-login
description: Authenticate Claude Code in a sandbox container against Azure AI Foundry using the Azure CLI device-code flow (RBAC / AAD identity, no ANTHROPIC_FOUNDRY_API_KEY). Use whenever a sandbox is created from the python stack and Claude Code must route through Foundry.
---

# Azure Foundry Login (sandbox containers)

Routes `sandbox <name> --claude` through Azure AI Foundry using the host user's AAD identity instead of an `ANTHROPIC_FOUNDRY_API_KEY`. Authentication uses `az login --use-device-code` because the container has no browser and cannot reuse the host's `~/.azure/` token cache.

## What ships with the sandbox

The `python` stack installs the Azure CLI inside the golden image (`stacks/python.sh`):

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

## End-to-end sequence

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
5. Verify:
   ```bash
   az account show
   az cognitiveservices account list
   ```
6. Launch Claude Code:
   ```bash
   sandbox <name> --claude
   ```

## Token persistence

- `~/.azure/` lives on the container's filesystem — survives `sandbox-stop` / `sandbox-start`.
- Re-login required after: `sandbox-stop --rm`, `sandbox-nuke`, or refresh-token expiry (typically weeks).
- Each parallel sandbox needs its own `az login` (one per container).

## When to bind-mount `~/.azure/` (don't, by default)

Mounting the host's `~/.azure/` into the container avoids re-login per sandbox but breaks isolation — agents in the container can read/refresh the host's tokens. Only consider it if the per-container login friction outweighs the security cost.

## Restricted-domain mode

If `--restrict-domains` is enabled, the four Azure domains above are already in `domains/anthropic-default.txt`. For a project-specific allowlist (`~/.sandbox/allowed-domains.txt`), add them explicitly:

```
login.microsoft.com
.microsoftonline.com
management.azure.com
.services.ai.azure.com
```
