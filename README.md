# extra-container

Manage declarative NixOS containers like imperative containers, without system
rebuilds.

Each declarative container adds a full system module evaluation to every NixOS rebuild,
which can be prohibitively slow for systems with many containers or when experimenting
with single containers.

On the other hand, the faster imperative containers lack the full range of options of declarative containers.
This tool brings you the best of both worlds.

## Example

```bash

sudo extra-container add --start <<'EOF'
{
  containers.demo = {
    privateNetwork = true;
    hostAddress = "10.250.0.1";
    localAddress = "10.250.0.2";

    config = { pkgs, ... }: {
      networking.firewall.allowedTCPPorts = [ 50 ];

      systemd.services.hello = {
        wantedBy = [ "multi-user.target" ];
        script = ''
          while true; do
            echo hello | ${pkgs.netcat}/bin/nc -lN 50
          done
        '';
      };
    };
  };
}
EOF

curl 10.250.0.2:50 # Returns 'hello' from the container

# Now change the 'hello' string in the container definition to something
# else and re-run the `extra-container add --start` command.
# The updated container will be automatically restarted.

# The container is a regular container that can be controlled
# with nixos-container
nixos-container status demo

# Remove the container
sudo extra-container destroy demo
```

## Install

```nix
{ pkgs, ... }:
let
  extra-container = pkgs.callPackage (fetchGit {
    url = "https://github.com/erikarvstedt/extra-container.git";
    # Recommended: Specify a git revision hash
    # rev = "...";
  }) {};
in
{
  systemPackages = [ extra-container ];
}
```

## Usage
```
extra-container add NIXOS_CONTAINER_CONFIG_FILE
                    [--attr|-A attrPath]
                    [--nixos-path path]
                    [--start|-s | --restart-changed|-r]

    NIXOS_CONTAINER_CONFIG_FILE is a NixOS config file with container
    definitions like 'containers.mycontainer = { ... }'

    --attr | -A attrPath
      Select an attribute from the config expression

    --nixos-path
      A nix expression that returns a path to the NixOS source
      to use for building the containers

    --start | -s
      Start all added containers
      Restart running containers that have changed

    --restart-changed | -r
      Restart running containers that have changed

    Example:
      extra-container add mycontainers.nix --restart-changed

      extra-container add mycontainers.nix --nixos-path \
        '"${fetchTarball https://nixos.org/channels/nixos-unstable/nixexprs.tar.xz}/nixos"'

echo NIXOS_CONTAINER_CONFIG | extra-container add
    Read the container config from stdin

    Example:
      extra-container add --start <<EOF
        { containers.hello = { enableTun = true; config = {}; }; }
      EOF

extra-container add STORE_PATH
    Add containers from STORE_PATH/etc

    Examples:
      Add from nixos system derivation
      extra-container add /nix/store/9h..27-nixos-system-foo-18.03

      Add from nixos etc derivation
      extra-container add /nix/store/32..9j-etc

extra-container build NIXOS_CONTAINER_CONFIG_FILE
    Build the container config and print the resulting NixOS system etc path

    This command can be used like 'add', but options related
    to starting are not supported

extra-container list
    List all extra containers

extra-container destroy CONTAINER

extra-container destroy --all|-a
    Destroy all extra containers

extra-container CMD ARGS...
    All other commands are forwarded to nixos-container
```

## Implementation

Take a NixOS config with container definitions, assign dummy values to some required
options like `fileSystems."/"` and build the resulting system derivation.

Now link the container files from system derivation to the main system, like so:
```
nixos-system/etc/systemd/system/container@CONTAINER.service -> /etc/systemd-mutable/system
nixos-system/etc/containers/CONTAINER.conf -> /etc/containers
```
Finally, add gcroots pointing to the linked files.


## Developing
All contributions and suggestions are welcome, even if they're minor or cosmetic.

Run `test.sh` for tests.

The tests add and remove temporary containers named `test-*` on the main
system.
Due to a [NixOS bug](https://github.com/NixOS/nixpkgs/issues/40355), it's currently not possible to run
nix builds inside a container.
A future fix will allow all tests to be run in a container to reduce interference
with the main system.
