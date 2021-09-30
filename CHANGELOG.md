# 0.8 (2021-09-30)
- Enhancements
  - Support NixOS and unstable
- Fixes
  - Fix flake
# 0.7 (2021-08-03)
- Enhancements
  - Support NixOS 21.05 and unstable
  - Add basic [Nix flake](https://nixos.wiki/wiki/Flakes) support
    for installing and developing.\
    `extra-container` itself still uses `nix-build` internally.
# 0.6 (2021-02-05)
- Fixes
  - Add compatibility with current NixOS unstable.
  - `extra.exposeLocalhost`: don't fail when iptables lock can't be obtained immediately.
  - Fix `PATH` not being preserved in container shells.
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
