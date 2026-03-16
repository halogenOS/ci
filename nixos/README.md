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
export GITHUB_TOKEN="ghp_..."
export UPLOAD_API_KEY="..."
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

Add your device configuration under `devices/`, then build the image:

```
nix build 'path:.#nixosConfigurations.<device>.config.system.build.image'
```

Flash the resulting image to the system disk, boot, and drop in the credential files.
