# xos-builder NixOS

Foundrix-based NixOS configuration for the XOS CI build server.

## Credentials

The following files must be placed on the target system under `/var/credentials/`.
On image-based deployments with runtime `/var` partitioning, these persist across reboots.

### `/var/credentials/buildkite-agent-token`

Plain text file containing the Buildkite agent registration token.
Obtain this from the Buildkite "Agents" settings page.

```
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

### `/var/credentials/buildkite-credentials`

Shell file sourced during the Buildkite environment hook.
Export any secrets your pipelines need:

```sh
# GitHub
export GITHUB_TOKEN="ghp_..."
export GITHUB_USER="..."
#export GITHUB_BUILDS_OWNER="halogenOS" → not needed for XOS
#export GITHUB_BUILDS_REPO="builds" → not needed for XOS

# Discord notifications
export DISCORD_BOT_URL="https://..."
export DISCORD_BOT_TOKEN="..."

# Telegram notifications
export TG_API_KEY="..."
export TG_CHAT_ID_DEVICE_<uppercase device name, for example GUACAMOLE>="..."
```

Variables matching the following patterns are automatically redacted from logs:
`*_PASSWORD`, `*_SECRET`, `*_TOKEN`, `*_ACCESS_KEY`, `*_SECRET_KEY`, `*_BOT_URL`, `*_API_KEY`

### `/var/credentials/xos-signing-keys/`

Directory containing AOSP signing keys. Exposed to builds as `$KEYS_DIR`.

## Module options

### `services.xos-buildkite`

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `tokenPath` | path | `/var/credentials/buildkite-agent-token` | Path to a file containing the Buildkite agent token |
| `organizationSlug` | string | `"halogenos"` | Buildkite organization slug for conditional hook logic |
| `tags` | attrs of string | `{ os = "nixos"; for = "halogenos"; }` | Agent tags |
| `buildDir` | path | `/var/lib/buildkite-agent/builds` | Directory where builds run |
| `spawn` | int | `1` | Number of parallel agents to spawn |
| `priority` | int | `1` | Agent priority (higher = assigned work first) |
| `noCommandEval` | bool | `true` | Disallow arbitrary console commands |
| `credentialsFile` | null or path | `null` | Path to a shell file with credential exports, sourced in the environment hook |
| `signingKeysDir` | null or path | `/var/credentials/xos-signing-keys` | Path to directory containing XOS AOSP signing keys |
| `extraPackages` | list of package | `[]` | Additional packages available to the buildkite agent |
| `ccache.enable` | bool | `false` | Enable ccache for builds |
| `ccache.dir` | path | `/var/cache/ccache` | ccache directory |
| `ccache.maxSize` | string | `"80G"` | Maximum ccache size |

## Deploying

Add your device configuration under `devices/`.

### Initial install

Build a flasher USB image (TUI-based installer):

```
nix build 'path:.#<hostname>/flasher:x86_64'
```

Write the result to a USB drive, boot from it, and follow the on-screen instructions.

### Updating

Rebuild remotely (or locally) using the device-specific configuration:

```
nixos-rebuild switch --flake 'path:.#<hostname>' --target-host user@<hostname> --sudo --ask-sudo-password --no-reexec
```

### Building the raw image

The flasher flashes the raw disk image, which can also be built directly:

```
nix build 'path:.#<hostname>/image:x86_64'
```

After first boot, drop in the credential files under `/var/credentials/`.
