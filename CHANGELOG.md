# Changelog

## 0.1.3

- Fix rebootstrap on already-animated characters: stop stale `Animator` tracks before starting Animate; wait for `AnimationPlayed` after connecting the listener (no false-positive skip when tracks were already playing).
- `replacementAnimateChildren` always `:Clone()`'s each child onto the bootstrapped script (sources stay untouched until the caller destroys them).
- Example client: snapshot client Animate children, bootstrap, then destroy the client script.

## 0.1.2

- Initial public release.
