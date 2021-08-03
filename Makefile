all: test

test: runTests checkFlake

runTests:
	nix develop -c sudo run-tests-in-container.sh

checkFlake:
	nix flake check

.PHONY: runTests checkFlake test
