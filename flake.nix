{
  description = "Run declarative NixOS containers without full system rebuilds";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/21.11";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
    let
      supportedSystems = [ "x86_64-linux" "i686-linux" "aarch64-linux" ];
      pkg = pkgs: pkgs.callPackage ./. { pkgSrc = ./.; };
    in
    {
      nixosModule = { pkgs, ... }: {
        environment.systemPackages = [ (pkg pkgs) ];
        boot.extraSystemdUnitPaths = [ "/etc/systemd-mutable/system" ];
      };

      overlay = final: prev: { extra-container = pkg final; };

    } // (flake-utils.lib.eachSystem supportedSystems (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      rec {
        defaultPackage = pkg pkgs;

        # This dev shell allows running the `extra-container` command directly from the local
        # source (./extra-container), for quick edit/test cycles.
        # This only works when `nix develop` is started from the repo root directory.
        devShell = pkgs.stdenv.mkDerivation {
          name = "shell";
          packages = with pkgs; [
            nixos-container
            openssh
          ];
          shellHook =  ''
            # Enable calling the local source (./extra-container) with command `extra-container`
            export PATH="$(realpath .)''${PATH:+:}$PATH"

            # Use the pinned nixpkgs for building containers when running `extra-container`
            export NIX_PATH="nixpkgs=${nixpkgs}''${NIX_PATH:+:}$NIX_PATH"

            # See comment in ./extra-container for an explanation
            export LOCALE_ARCHIVE=${pkgs.glibcLocales}/lib/locale/locale-archive
          '';
        };

        packages = {
          # Run a basic extra-container test in a NixOS VM
          test = pkgs.nixosTest {
            name = "extra-container";

            machine = {
              imports = [ self.nixosModule ];
              virtualisation.memorySize = 1024; # Needed for evaluating the container system
              nix.nixPath = [ "nixpkgs=${nixpkgs}" ];
              # Pre-build the container used by testScript
              system.extraDependencies = let
                basicContainer = import ./eval-config.nix {
                  nixosPath = "${nixpkgs}/nixos";
                  inherit system;
                  systemConfig = {
                    containers.test.config.environment.etc.testFile.text = "testSuccess";
                  };
                };
              in [ basicContainer.config.system.build.etc ];
            };

            testScript = ''
              config = '{ containers.test.config.environment.etc.testFile.text = "testSuccess"; }'
              output = machine.succeed(
                f"extra-container shell -E '{config}' --run c cat /etc/testFile"
              )
              if not "testSuccess" in output:
                print(f"Test failed. Output:\n{output}")
            '';
          };

          # Used by apps.vm
          vm = (import "${nixpkgs}/nixos" {
            inherit system;
            configuration = { pkgs, lib, ... }: with lib; {
              virtualisation.graphics = false;
              services.getty.autologinUser = "root";
              nix.nixPath = [ "nixpkgs=${nixpkgs}" ];
              imports = [ self.nixosModule ];
              # Pre-build a minimal container
              system.extraDependencies = let
                basicContainer = import ./eval-config.nix {
                  nixosPath = "${nixpkgs}/nixos";
                  inherit system;
                  systemConfig = {};
                };
              in [ basicContainer.config.system.build.etc ];
            };
          }).vm;

          runVM = pkgs.writers.writeBash "run-vm" ''
            set -euo pipefail
            export NIX_DISK_IMAGE=/tmp/extra-container-vm-img
            rm -f $NIX_DISK_IMAGE
            trap "rm -f $NIX_DISK_IMAGE" EXIT

            export QEMU_OPTS="-smp $(nproc) -m 2000"
            ${packages.vm}/bin/run-*-vm
          '';

          debugTest = pkgs.writers.writeBash "run-debug-test" ''
            set -euo pipefail
            export TMPDIR=$(mktemp -d)
            trap "rm -rf $TMPDIR" EXIT

            export QEMU_OPTS="-smp $(nproc) -m 2000"
            export tests='start_all(); import code; code.interact(local=globals())'
            ${packages.test.driver}/bin/nixos-test-driver
          '';

          updateReadme = pkgs.writers.writeBash "update-readme" ''
            exec ${pkgs.ruby}/bin/ruby ${toString ./util/update-readme.rb}
          '';
        };

        apps = {
          # Run a NixOS VM where extra-container is installed
          vm = {
            type = "app";
            program = toString packages.runVM;
          };

          # Run a Python test driver shell inside the test VM
          debugTest = {
            type = "app";
            program = toString packages.debugTest;
          };

          updateReadme = {
            type = "app";
            program = toString packages.updateReadme;
          };
        };

        checks = { inherit (packages) test; };
      }
    ));
}
