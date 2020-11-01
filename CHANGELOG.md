# 0.5 (2020-11-01)
- Enhancements. (See the [README](README.md) for full documentation.)
  - Add generic support for systemd-based Linux distros.
  - Add command `shell`.
  - Add extra container options:\
    `extra.enableWAN`\
    `extra.exposeLocalhost`\
    `extra.firewallAllowHost`\
    See [eval-config.nix](eval-config.nix) for descriptions.
  - Add option `--ssh`.
  - Add option `--expr|-E`.
  - Append `pwd` to `NIX_PATH` to allow accessing the working dir in non-file configs.
  - Support nixpkgs versions > 20.03.
  - Automatically run as root via `sudo`.
- Fixes
  - Don't copy local nixpkgs sources provided via `--nixpkgs` to the nix store.

# 0.4 (2020-09-25)
- Enhancements
  - Significantly speed up container evaluation.\
    Use a reduced module set for evaluating the container host system derivation.
  - Speed up container destruction.\
    Kill the container process instead of a clean shutdown.
