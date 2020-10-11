#!/usr/bin/env bash

set -euo pipefail

# Install extra-container on a non-NixOS systemd-based system for use with sudo.
# Requires a multi-user nix installation, because extra-container runs nix-build as root.
# This script is idempotent.

[[ -e /run/booted-system/nixos-version ]] && isNixos=1 || isNixos=
[[ -e /run/systemd/system ]] && hasSystemd=1 || hasSystemd=
scriptDir=$(cd "${BASH_SOURCE[0]%/*}" && pwd)

if [[ $EUID == 0 ]]; then
    echo "This script should NOT be run as root."
    exit 1
fi
if [[ $isNixos ]]; then
    echo "This install script is not needed on NixOS. See the README for installation instructions."
    exit 1
fi
if [[ ! $hasSystemd ]]; then
    echo "extra-container requires systemd."
    exit 1
fi
if [[ ! -e /nix/var/nix/profiles/default/bin ]]; then
    echo "extra-container requires a multi-user nix installation."
    exit 1
fi

## 1. Build extra-container
tmpDir=$(mktemp -d)
trap "rm -rf $tmpDir" EXIT
nix-build --out-link $tmpDir/extra-container -E "(import <nixpkgs> {}).callPackage ''$scriptDir/..'' {}"

## 2. Install to root user profile
sudo $(type -P nix-env) -i $tmpDir/extra-container

## 3. Edit /etc/sudoers to enable running extra-container via sudo
# See ./edit-sudoers.rb for more details
if ! type -P ruby > /dev/null; then
    nix-build --out-link $tmpDir/ruby '<nixpkgs>' -A ruby
    export PATH="$tmpDir/ruby/bin${PATH:+:}$PATH"
fi

extraSecurePaths=/root/.nix-profile/bin:/nix/var/nix/profiles/default/bin

newSudoersContent=$(sudo cat /etc/sudoers | ruby "$scriptDir"/generate-sudoers.rb "$extraSecurePaths")
if [[ $newSudoersContent ]]; then
    echo "$newSudoersContent" | sudo EDITOR="tee" visudo >/dev/null
fi
