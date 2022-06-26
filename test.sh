#!/usr/bin/env bash

set -euo pipefail
shopt -s nullglob

scriptDir="$(dirname "$(readlink -f "$0")")"
PATH=$scriptDir:$PATH

cleanup() {
    set +e
    for container in $(extra-container list | grep ^test-); do
        extra-container destroy $container
    done
    set -e
}
trap "cleanup" EXIT

reportError() {
    echo "Error on line $1"
}
trap 'reportError $LINENO' ERR

testMatches() {
    actual="$1"
    expected="$2"
    if [[ $actual != $expected ]]; then
        echo
        echo 'Pattern does not match'
        echo 'Expected:'
        echo "$expected"
        echo
        echo 'Actual:'
        echo "$actual"
        echo
        return 1
    fi
}

# This significantly reduces eval time. Not needed for NixOS ≥ 20.03
baseConfig='config = { documentation.nixos.enable = false; }'

cleanup

#―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
echo "Test attr arg and container starting "

output=$(extra-container create -A 'a b' --start <<EOF
{
  "a b" = { config, pkgs, ... }: {
    containers.test-1 = {
      $baseConfig;
    };
  };
}
EOF
)

testMatches "$output" "*Installing*test-1*Starting*test-1*"

#―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
echo "Test starting and updating"

output=$(extra-container create -s <<EOF
{ config, pkgs, ... }:
{
  containers.test-1 = {
    $baseConfig // { environment.variables.foo = "a"; };
  };
  containers.test-2 = {
    $baseConfig;
  };
}
EOF
)

testMatches "$output" "*Starting*test-2*Updating*test-1*"

#―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
echo "Test unchanged"

output=$(extra-container create -s <<EOF
{ config, pkgs, ... }:
{
  containers.test-1 = {
    $baseConfig // { environment.variables.foo = "a"; };
  };
}
EOF
)

testMatches "$output" "*test-1 (unchanged, skipped)*"

#―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
echo "Test updating and restarting"

output=$(extra-container create -u <<EOF
{ config, pkgs, ... }:
{
  containers.test-1 = {
    $baseConfig // { environment.variables.foo = "b"; };
  };
  containers.test-2 = {
    privateNetwork = true;
    $baseConfig;
  };
}
EOF
)

testMatches "$output" "*Updating*test-1*Restarting*test-2*"

#―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
echo "Test shell run"

read -d '' src <<EOF || true
{ config, pkgs, ... }:
{
  containers.test-1 = {
    $baseConfig;
  };
}
EOF
output=$(extra-container shell -E "$src" --run c uname -a)
testMatches "$output" "*Linux test*"

# Container should be destroyed after running
[[ ! -e /var/lib/containers/test-1 ]]

#―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
echo "Test manual build"

storePath=$(extra-container build <<EOF
{ config, pkgs, ... }:
{
  containers.test-1 = {
    $baseConfig;
  };
}
EOF
)

testMatches "$storePath" "/nix/store/*"

output=$(extra-container create -s $storePath)
testMatches "$output" "*Starting*test-1*"

#―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
echo "Test list"

output=$(extra-container list | grep ^test- || true)
testMatches "$output" "test-1*test-2"

#―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
echo "Test destroy"

[[ $(echo /var/lib/containers/test-*) ]]
cleanup
output=$(extra-container list | grep ^test- || true)
testMatches "$output" ""
[[ ! $(echo /var/lib/containers/test-*) ]]
