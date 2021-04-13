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

sudo extra-container create --start <<'EOF'
{
  containers.demo = {
    privateNetwork = true;
    hostAddress = "10.250.0.1";
    localAddress = "10.250.0.2";

    config = { pkgs, ... }: {
      systemd.services.hello = {
        wantedBy = [ "multi-user.target" ];
        script = ''
          while true; do
            echo hello | ${pkgs.netcat}/bin/nc -lN 50
          done
        '';
      };
      networking.firewall.allowedTCPPorts = [ 50 ];
    };
  };
}
EOF

curl 10.250.0.2:50 # Returns 'hello' from the container

# Now change the 'hello' string in the container definition to something
# else and re-run the `extra-container create --start` command.
# The container is automatically updated via NixOS' `switch-to-configuration`.

# The container is a regular container that can be controlled
# with nixos-container
nixos-container status demo

# Remove the container
sudo extra-container destroy demo
```

## Changelog

 [`CHANGELOG.md`](CHANGELOG.md)

## Install


#### On NixOS
```nix
{ pkgs, ... }:
let
  extra-container = let
    src = builtins.fetchGit {
      url = "https://github.com/erikarvstedt/extra-container.git";
      # Recommended: Specify a git revision hash
      # rev = "...";
    };
  in
    pkgs.callPackage src { pkgSrc = src; };
in
{
  environment.systemPackages = [ extra-container ];
  # if on NixOS > 20.09:
  boot.extraSystemdUnitPaths = [ "/etc/systemd-mutable/system" ];
}
```

#### On other systemd-based Linux distros

```bash
git clone https://github.com/erikarvstedt/extra-container
# Calls sudo during install
extra-container/util/install.sh
```
[`install.sh`](util/install.sh) installs `extra-container` to the root nix user profile
and edits `/etc/sudoers` to enable running `extra-container` with sudo.

## More features

### Shell

Command `shell` starts a container shell session.
The shell provides helper functions for interacting with the container. The container is destroyed when exiting the shell.

This config uses `extra` options that are [explained below](#private-network-helper).
```bash
read -d '' src <<'EOF' || :
{
  containers.demo = {
    extra.addressPrefix = "10.250.0"; # Sets up a private network.
    extra.enableWAN = true;
  };
}
EOF
# Provide container config via `-E` instead of stdin because the shell requires
# access to the terminal's stdin.
extra-container shell -E "$src" --ssh
```

`extra-container` automatically runs itself via `sudo` when called as a non-root user.

An example shell session
```
...
Starting shell.
Enter "h" for documentation.

$ h
Container address: 10.250.0.2 ($ip)
Container filesystem: /var/lib/containers/demo

Run "c COMMAND" to execute a command in the container
Run "c" to start a shell session inside the container
Run "cssh" for SSH

# Container internet access, enabled via option `extra.enableWAN`
$ c curl example.com
<!doctype html>
<html>
...

# Connect with SSH, enabled by `--ssh`
$ cssh hostname
demo
```

#### Run commands

Run a command in a shell session and exit. The container is destroyed afterwards.
```bash
cfg='{ containers.demo.config = {}; }'
extra-container shell -E "$cfg" --run c hostname
# => demo
```

Start a shell inside the container.
```bash
cfg='{ containers.demo.config = {}; }'
extra-container shell -E "$cfg" --run c
```

#### Repeated calls to `extra-container shell`
When `extra-container shell` detects that it is already running in a container shell
session, it updates the running container instead of destroying and restarting it and
starting a new shell.\
To prevent `sudo` from clearing the environment variables that are needed for shell
detection, call `extra-container` without `sudo`.\
`extra-container` will automatically run itself via `sudo` only when it is first
called as a non-root user outside of a shell session.

To force container destruction inside a shell session, use `extra-container shell --destroy|-d`.

#### Disable auto-destruction
By default, `shell` destroys the shell container before starting and before exiting.
This ensures that containers start with no leftover filesystem state from
previous runs and that containers do not consume system resources after use.\
To disable auto-destructing containers, run
`extra-container shell --no-destroy|-n`


### Private network helper

Container options `extra.*` are defined by `extra-container` and help with setting up private network containers.\
See [eval-config.nix](./eval-config.nix) for full option descriptions.
```nix
containers.demo = {
  extra = {
    # Sets
    # privateNetwork = true
    # hostAddress = "${addressPrefix}.1"
    # localAddress = "${addressPrefix}.2"
    addressPrefix = "10.250.0";

    # Enable internet access for the container
    enableWAN = true;
    # Always allow connections from hostAddress
    firewallAllowHost = true;
    # Make the container's localhost reachable via localAddress
    exposeLocalhost = true;
  }
};
```

### Access working dir in non-file configs

`extra-container` appends `pwd` to `NIX_PATH` to allow configs given via `--expr|-E`
or via stdin to access the working directory.
```bash
extra-container create -E '{ imports = [ <pwd/myfile.nix> ]; ... }'
```

## Usage
```
extra-container create <container-config-file>
                       [--attr|-A attrPath]
                       [--nixpkgs-path|--nixos-path path]
                       [--start|-s | --restart-changed|-r]
                       [--ssh]
                       [--build-args arg...]

    <container-config-file> is a NixOS config file with container
    definitions like 'containers.mycontainer = { ... }'

    --attr | -A attrPath
      Select an attribute from the config expression

    --nixpkgs-path
      A nix expression that returns a path to the nixpkgs source
      to use for building the containers

    --nixos-path
      Like '--nixpkgs-path', but for directly specifying the NixOS source

    --start | -s
      Start all created containers
      Update running containers that have changed or restart them if '--restart-changed' was specified

    --update-changed | -u
      Update running containers with a changed system configuration by running
      'switch-to-configuration' inside the container.
      Restart containers with a changed container configuration

    --restart-changed | -r
      Restart running containers that have changed

    --ssh
      Generate SSH keys in /tmp and enable container SSH access.
      The key files remain after exit and are reused on subsequent runs.
      Unlocks the function 'cssh' in 'extra-container shell'.
      Requires container option 'privateNetwork = true'.

    --build-args arg...
      All following args are passed to nix-build.

    Example:
      extra-container create mycontainers.nix --restart-changed

      extra-container create mycontainers.nix --nixpkgs-path \
        'fetchTarball https://nixos.org/channels/nixos-unstable/nixexprs.tar.xz'

      extra-container create mycontainers.nix --start --build-args --builders 'ssh://worker - - 8'

echo <container-config> | extra-container create
    Read the container config from stdin

    Example:
      extra-container create --start <<EOF
        { containers.hello = { enableTun = true; config = {}; }; }
      EOF

extra-container create --expr|-E <container-config>
    Provide container config as an argument

extra-container create <store-path>
    Create containers from <store-path>/etc

    Examples:
      Create from nixos system derivation
      extra-container create /nix/store/9h..27-nixos-system-foo-18.03

      Create from nixos etc derivation
      extra-container create /nix/store/32..9j-etc

extra-container shell ...
    Start a container shell session.
    See the README for a complete documentation.
    Supports all arguments from 'create'

    Extra arguments:
      --run <cmd> <arg>...
        Run command in shell session and exit
        Must be the last option given
      --no-destroy|-n
        Do not destroy shell container before and after running
      --destroy|-d
        If running inside an existing shell session, force container to
        be destroyed before and after running

    Example:
      extra-container shell -E '{ containers.demo.config = {}; }'

extra-container build ...
    Build the container config and print the resulting NixOS system etc path

    This command can be used like 'create', but options related
    to starting are not supported

extra-container list
    List all extra containers

extra-container restart <container>...
    Fixes the broken restart command of nixos-container (nixpkgs issue #43652)

extra-container destroy <container>...

extra-container destroy --all|-a
    Destroy all extra containers

extra-container <cmd> <arg>...
    All other commands are forwarded to nixos-container
```

## Implementation

The script works like this: Take a NixOS config with container definitions and build
the system's `config.system.build.etc` derivation. Because we're not building a full
system we can use a reduced module set (`eval-config.nix`) to improve evaluation
performance.

Now link the container files from the etc derivation to the main system, like so:
```
nixos-system/etc/systemd/system/container@CONTAINER.service -> /etc/systemd-mutable/system
nixos-system/etc/containers/CONTAINER.conf -> /etc/containers
```
Finally, add gcroots pointing to the linked files.


## Developing
All contributions and suggestions are welcome, even if they're minor or cosmetic.

For tests run `test.sh` or `run-tests-in-container.sh` to reduce interference with your main system.

The tests add and remove temporary containers named `test-*` on the host system.

When changing the `Usage` documentation in `extra-container`, run `./update-readme` to copy
these changes to `README.md`.
