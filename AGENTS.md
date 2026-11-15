# AGENTS.md

## Nix

- Express host/OS differences through which modules a host imports, not through conditionals inside a module (`lib.mkIf`, `stdenv.hostPlatform.isDarwin`, ...). Before adding a branch to a shared module, check whether the host's import list can express the difference instead.
- A conditional is acceptable only when imports cannot express it: varying part of a single host, or package overrides.
