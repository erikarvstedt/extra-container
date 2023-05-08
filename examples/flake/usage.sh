## Usage via `nix run`

#―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
# Container lifecycle

# Create and start container defined by ./flake.nix
nix run . -- create --start
# After changing ./flake.nix, you can also use this command to update
# the (running) container.
#
# The arguments after `--` are passed to the `extra-container` binary in PATH,
# while the flake is used for the container definitions.

# Use `nixos-container` to control the running container
sudo nixos-container run demo -- hostname
sudo nixos-container root-login demo

# Destroy container
nix run . -- destroy

#―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
# Container shell
# Start an interactive shell in an ephemeral container
nix run . -- shell
nix run . # equivalent, because `shell` is used as the default command

# Run a single command in the container.
# The container is destroyed afterwards.
nix run . -- --run c hostname
nix run . -- shell --run c hostname # equivalent
nix run . -- --run bash -c 'curl --http0.9 $ip:50'

#―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
# Usage via `nix build`
# 1. Build container
nix build . --out-link /tmp/container
# 2. Run container
extra-container shell /tmp/container

#―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
# Inspect container configs
nix eval . --apply 'sys: sys.containers.demo.config.networking.hostName'
