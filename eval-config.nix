nixosPath: systemConfig:

let
  nixos = toString nixosPath;

  # A minimal module set for evaluating container configs.
  # Compatible with nixpkgs >= 16.09.
  #
  # On my system, this reduces the extra-container overhead (total eval time - container eval time)
  # to 270 ms compared to 2200 ms for a full nixos evaluation.
  baseModules = [
    "${nixos}/modules/misc/assertions.nix"
    "${nixos}/modules/misc/nixpkgs.nix"
    "${nixos}/modules/system/activation/top-level.nix"
    "${nixos}/modules/system/etc/etc.nix"
    "${nixos}/modules/system/boot/systemd.nix"
    "${nixos}/modules/virtualisation/containers.nix"
    ({ lib, ... }: let
      optionValue = default: lib.mkOption { inherit default; };
    in {
      # Top-level config attrs need corresponding option definitions
      # even if they are unused.
      # Add dummy definitions instead of costly module imports.
      options = {
        boot.kernel = {};
        boot.kernelModules = {};
        environment.profiles = {};
        environment.systemPackages = {};
        networking = {};
        nix = {};
        security = {};
        services = {
          dbus = {};
          udev = {};
          rsyslogd.enable = optionValue false;
          syslog-ng.enable = optionValue false;
        };
        system.activationScripts = optionValue "";
        system.path = optionValue "";
        system.requiredKernelConfig = {};
        users = {};
     };
    })
  ];
in
import "${nixos}/lib/eval-config.nix" {
  inherit baseModules;
  modules = [ systemConfig ];
}
