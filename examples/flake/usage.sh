## Usage via `nix run`

# Create container defined by ./flake.nix
nix run . -- create
# The arguments after `--` are passed to the `extra-container` binary in PATH,
# while the flake is used for the container definitions.

# Destroy container
nix run . -- destroy

# Start an interactive shell in the container
nix run . -- shell
nix run . # equivalent, because `shell` is used as the default command

# Run a single command in the container.
# The container is destroyed afterwards.
nix run . -- --run c hostname
nix run . -- shell --run c hostname # equivalent
nix run . -- --run bash -c 'curl --http0.9 $ip:50'


## Usage via `nix build`
# 1. Build container
nix build . --out-link /tmp/container
# 2. Run container
extra-container shell /tmp/container


## Inspect container configs
nix eval . --apply 'sys: sys.containers.demo.config.networking.hostName'
