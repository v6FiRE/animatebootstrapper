# AnimateBootstrapper

Run Roblox's stock **Animate** `LocalScript` on client-owned characters (NPCs from `CreateHumanoidModelFromDescriptionAsync`, custom client models, etc.) **without forking Animate**.

`LocalScript`s only run under `PlayerScripts`, `PlayerGui`, `Backpack`, or the local player's `Character`. An NPC sitting in `workspace` does not qualify, so its Animate script never runs. This package works around that by briefly parenting the model into a valid container, starting stock Animate, then parking the script under `PlayerScripts` while the model lives wherever you need it.

**Client-only.** Requires stock R6/R15 Animate behavior.

## Installation

```toml
# wally.toml
[dependencies]
AnimateBootstrapper = "v6fire/animatebootstrapper@0.1.2"
```

```bash
wally install
```

```luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AnimateBootstrapper = require(ReplicatedStorage.Packages.AnimateBootstrapper)
```

Adjust the require path to match your Rojo `Packages` layout.

## Server setup (required)

The Animate `LocalScript` you clone **must be created on the server and replicated to the client**. A `LocalScript` bundled with a client-created model from `CreateHumanoidModelFromDescriptionAsync` will misbehave in live games (works in Studio, fails in Live).

This package does not create or name those templates for you. Your game is responsible for:

1. Creating stock Animate `LocalScript`s on the **server** (one per rig type you need).
2. Replicating them to the client (e.g. `ReplicatedStorage`, a folder, or another container you already use for assets).
3. Passing the appropriate template into `BootstrapAnimate` from client code.

See [`examples/server`](examples/server) for one demo approach — the instance names there (`BaseAnimateR6`, `BaseAnimateR15`) are **example-place conventions**, not part of this library's API.

For background on the replication issue, see the [DevForum thread](https://devforum.roblox.com/t/studio-vs-live-server-discrepancy-failure-with-animate-script-generated-by-createhumanoidmodelfromdescriptionasync/4685167).

## Usage

Bootstrap **before** parenting the character into `workspace` (or anywhere visible) to avoid a brief flash while the model is reparented during setup.

```luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AnimateBootstrapper = require(ReplicatedStorage.Packages.AnimateBootstrapper)

-- A server-replicated stock Animate LocalScript from your game's setup (see above).
local animateTemplate: LocalScript = ...

local character: Model = ... -- Humanoid + Animator; not yet parented to workspace

AnimateBootstrapper.BootstrapAnimate(character, animateTemplate)

character.Parent = workspace
```

### Custom animation children

Pass a third argument to replace all children of the cloned Animate script (animation instances, etc.):

```luau
AnimateBootstrapper.BootstrapAnimate(character, animateTemplate, customAnimateChildren)
```

This calls `ClearAllChildren()` on the clone before inserting your instances. A common pattern when using `CreateHumanoidModelFromDescriptionAsync` is to remove the client-bundled Animate script and pass its children here while cloning a server-replicated template for the script itself.

## API

### `AnimateBootstrapper.BootstrapAnimate(character, animateScript, replacementChildren?)`

| Parameter | Description |
|-----------|-------------|
| `character` | `Model` with a `Humanoid` and `Animator` |
| `animateScript` | Server-replicated stock Animate `LocalScript` to clone |
| `replacementChildren` | Optional `{ Instance }` — replaces all children of the clone |

**Returns:** The bootstrapped Animate `LocalScript`. Destroyed automatically when `character` is destroyed.

**Yields** until stock Animate plays its first idle animation (up to 3 seconds).

**Errors if:**

- Called on the server
- `Humanoid` or `Animator` is missing
- Animate does not start within the timeout (usually a replication or setup issue)

## Gotchas

- **Client-only** — do not require or call from server scripts.
- **Server-replicated Animate** — the package does not verify replication; that is your responsibility.
- **Bootstrap before showing** — reparenting during bootstrap can cause a visible flash.
- **Other LocalScripts on the character** — any `LocalScript` descendant of the model may also run during bootstrap.
- **Stock Animate coupling** — after idle starts, the script is moved to `PlayerScripts` because stock Animate caches `Humanoid`/`Animator` at startup. This relies on unmodified Roblox Animate behavior.
- **R6 and R15** — tested against default Roblox Animate scripts for both rig types.

## Examples

This repo includes a demo place for local testing:

```bash
rojo serve examples.project.json
```

| Path | Purpose |
|------|---------|
| [`examples/server`](examples/server) | Demo server setup that extracts stock Animate scripts and replicates them |
| [`examples/client`](examples/client) | Demo client that spawns NPCs, bootstraps Animate, and parents to `workspace` |

The examples include extra scaffolding (template naming, a `VerifyReplication` remote, NPC spawning) that illustrates one end-to-end workflow. Copy the patterns that fit your game; you do not need to match the demo names or remotes to use the package.

## License

MIT — see [LICENSE](LICENSE).
