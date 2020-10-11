#!/usr/bin/env bash

set -euo pipefail
shopt -s nullglob

scriptDir="$(dirname "$(readlink -f "$0")")"
PATH=$scriptDir:$PATH

cleanup() {
    # clean immutable files inside the container
    for f in /var/lib/containers/test-extra-container/var/lib/containers/*/var/empty; do
        chattr -i -a "$f"
        rm -rf "$f"
    done
    extra-container destroy test-extra-container || true
}
trap "cleanup" EXIT

reportError() {
    echo "Error on line $1"
}
trap 'reportError $LINENO' ERR

cleanup

#

nixpkgs=$(nix eval --raw '(toString <nixpkgs>)')

extra-container create -s <<EOF
{ config, pkgs, lib, ... }:
{
  containers.test-extra-container = {
    bindMounts."/extra-container".hostPath = "$scriptDir";
    bindMounts."/nixpkgs".hostPath = "$nixpkgs";
    config.environment = {
      systemPackages = [ pkgs.nixos-container ];
      variables.NIX_PATH = lib.mkForce "nixpkgs=/nixpkgs";
    };
  };
}
EOF

echo "Running tests"
echo
nixos-container run test-extra-container -- '/extra-container/test.sh'
