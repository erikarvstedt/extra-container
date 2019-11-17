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

cleanup

#
echo "Test attr arg and container starting "

output=$(extra-container create -A 'a b' --start <<'EOF'
{
  "a b" = { config, pkgs, ... }: {
    containers.test-1 = {
      config = {};
    };
  };
}
EOF
)

testMatches "$output" "*Installing*test-1*Starting*test-1*"

#
echo "Test starting and restarting"

output=$(extra-container create -s <<'EOF'
{ config, pkgs, ... }:
{
  containers.test-1 = {
    config.environment.variables.foo = "a";
  };
  containers.test-2 = {
    config = {};
  };
}
EOF
)

testMatches "$output" "*Starting*test-2*Restarting*test-1*"

#
echo "Test unchanged"

output=$(extra-container create -s <<'EOF'
{ config, pkgs, ... }:
{
  containers.test-1 = {
    config.environment.variables.foo = "a";
  };
}
EOF
)

testMatches "$output" "*test-1 (unchanged, skipped)*"

#
echo "Test restart"

output=$(extra-container create -r <<'EOF'
{ config, pkgs, ... }:
{
  containers.test-1 = {
    config.environment.variables.foo = "b";
  };
}
EOF
)

testMatches "$output" "*Restarting*test-1*"

#
echo "Test manual build"

storePath=$(extra-container build <<'EOF'
{ config, pkgs, ... }:
{
  containers.test-3 = {
      config = {};
  };
}
EOF
)

testMatches "$storePath" "/nix/store/*"

output=$(extra-container create -s $storePath)
testMatches "$output" "*Starting*test-3*"

#
echo "Test list"

output=$(extra-container list | grep ^test- || true)
testMatches "$output" "test-1*test-2*test-3"

#
echo "Test destroy"

[[ $(echo /var/lib/containers/test-*) ]]
cleanup
output=$(extra-container list | grep ^test- || true)
testMatches "$output" ""
[[ ! $(echo /var/lib/containers/test-*) ]]
