#!/usr/bin/env bash

set -euo pipefail
shopt -s nullglob

scriptDir="$(dirname "$(readlink -f "$0")")"
PATH=$scriptDir:$PATH

cleanup() {
    # clean immutable files inside the container
    for f in /var/lib/*containers/test-extra-container/var/lib/*containers/*/var/empty; do
        chattr -i -a "$f"
        rm -rf "$f"
    done
    extra-container destroy test-extra-container || true
}
trap "cleanup" EXIT

trap "echo \"Error at $(realpath ${BASH_SOURCE[0]}):\$LINENO\"" ERR

cleanup

#―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――

nixpkgs=$(nix-instantiate --eval -E '(toString <nixpkgs>)' | tr -d '"')

extra-container create -s <<EOF
{ config, pkgs, lib, ... }:
{
  containers.test-extra-container = {
    bindMounts."/extra-container".hostPath = "$scriptDir";
    bindMounts."/nixpkgs".hostPath = "$nixpkgs";
    config = { options, ... }: {
      environment = {
        systemPackages = [ pkgs.nixos-container ];
        variables.NIX_PATH = lib.mkForce "nixpkgs=/nixpkgs";
      };
      boot = lib.optionalAttrs (options.boot ? extraSystemdUnitPaths) {
        extraSystemdUnitPaths = [ "/etc/systemd-mutable/system" ];
      };
    };
  };
}
EOF

echo "Running tests"
echo
nixos-container run test-extra-container -- '/extra-container/test.sh'
