# AnimateBootstrapper

Run Roblox's stock **Animate** `LocalScript` on client-owned characters (NPCs from `CreateHumanoidModelFromDescriptionAsync`, custom client models, etc.) **without forking Animate**.

`LocalScript`s only run under `PlayerScripts`, `PlayerGui`, `Backpack`, or the local player's `Character`. An NPC sitting in `workspace` does not qualify, so its Animate script never runs. This package works around that by briefly parenting the model into a valid container, starting stock Animate, then parking the script under `PlayerScripts` while the model lives wherever you need it.

**Client-only.** Requires stock R6/R15 Animate behavior.

## Installation

```toml
# wally.toml
[dependencies]
AnimateBootstrapper = "v6FiRE/animatebootstrapper@0.1.0"
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

Create template Animate scripts on the server and parent them to `ReplicatedStorage` (or similar). See [`examples/server`](examples/server) for one approach.

For background on this replication issue, see the [DevForum thread](https://devforum.roblox.com/t/studio-vs-live-server-discrepancy-failure-with-animate-script-generated-by-createhumanoidmodelfromdescriptionasync/4685167).

## Usage

Bootstrap **before** parenting the character into `workspace` (or anywhere visible) to avoid a brief flash while the model is reparented during setup.

```luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AnimateBootstrapper = require(ReplicatedStorage.Packages.AnimateBootstrapper)

local baseAnimate = ReplicatedStorage:WaitForChild("BaseAnimateR15") :: LocalScript

local npc = -- ... your client-owned character model with Humanoid + Animator

AnimateBootstrapper.BootstrapAnimate(npc, baseAnimate)

npc.Parent = workspace
```

### Custom animation children

Pass a third argument to replace all children of the cloned Animate script (animation instances, etc.):

```luau
AnimateBootstrapper.BootstrapAnimate(npc, baseAnimate, customAnimateChildren)
```

This calls `ClearAllChildren()` on the clone before inserting your instances.

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

This repo includes a full demo place:

```bash
rojo serve
```

| Path | Purpose |
|------|---------|
| [`examples/server`](examples/server) | Creates `BaseAnimateR6` / `BaseAnimateR15` in `ReplicatedStorage` |
| [`examples/client`](examples/client) | Spawns NPCs, bootstraps Animate, parents to `workspace` |

The client example includes a `VerifyReplication` remote that demonstrates how to detect client-only instances at a network boundary. It is demo scaffolding, not a production replication check.

## Acknowledgments

README drafted with assistance from [Cursor](https://cursor.com).

## License

MIT — see [LICENSE](LICENSE).
