nixosPath: systemConfig:

let
  nixos = toString nixosPath;

  baseModules = if builtins.pathExists "${nixos}/modules/virtualisation/nixos-containers.nix"
                then baseModulesLatest
                else baseModules_20_03;

  # Minimal module sets for evaluating container configs.
  # They significantly reduce extra-container evaluation overhead (total eval time - container eval time)

  # Compatible with nixpkgs 16.09-20.03 (inclusive)
  baseModules_20_03 = [
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

  # Compatible with nixpkgs > 20.03
  baseModulesLatest = [
    "${nixos}/modules/misc/assertions.nix"
    "${nixos}/modules/misc/nixpkgs.nix"
    "${nixos}/modules/system/activation/top-level.nix"
    "${nixos}/modules/system/etc/etc.nix"
    "${nixos}/modules/system/boot/systemd.nix"
    "${nixos}/modules/virtualisation/nixos-containers.nix"
    ({ lib, ... }: let
      optionValue = default: lib.mkOption { inherit default; };
      dummy = optionValue [];
    in {
      options = {
        boot.kernel.sysctl = dummy;
        boot.kernelModules = dummy;
        environment.systemPackages = dummy;
        networking.dhcpcd.denyInterfaces = dummy;
        networking.extraHosts = dummy;
        networking.proxy.envVars = optionValue {};
        security = dummy;
        services = {
          dbus = dummy;
          udev = dummy;
          rsyslogd.enable = optionValue false;
          syslog-ng.enable = optionValue false;
        };
        system.activationScripts = dummy;
        system.path = optionValue "";
        system.nssDatabases = dummy;
        system.nssModules = dummy;
        system.requiredKernelConfig = dummy;
        ids.gids.keys = dummy;
        ids.gids.systemd-journal = dummy;
        ids.gids.systemd-journal-gateway = dummy;
        ids.uids.systemd-journal-gateway = dummy;
        ids.gids.systemd-network = dummy;
        ids.uids.systemd-network = dummy;
        ids.uids.systemd-resolve = dummy;
        ids.gids.systemd-resolve = dummy;
        users.users.systemd-network.uid = dummy;
        users.users.systemd-resolve.uid = dummy;
        users.users.systemd-journal-gateway.uid = dummy;
        users.groups.systemd-network.gid = dummy;
        users.groups.systemd-resolve.gid = dummy;
        users.groups.keys.gid = dummy;
        users.groups.systemd-journal.gid = dummy;
        users.groups.systemd-journal-gateway.gid = dummy;
     };
    })
  ];
in
import "${nixos}/lib/eval-config.nix" {
  inherit baseModules;
  modules = [ systemConfig ];
}
