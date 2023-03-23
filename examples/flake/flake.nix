# See how this flake is used in ./usage.sh
{
  inputs.extra-container.url = "github:erikarvstedt/extra-container";
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = { extra-container, ... }@inputs:
    extra-container.inputs.flake-utils.lib.eachSystem extra-container.lib.supportedSystems (system: {
      packages.default = extra-container.lib.buildContainers {
        # The system of the container host
        inherit system;

        # Only set this if the `system.stateVersion` of your container
        # host is < 22.05
        # legacyInstallDirs = true;

        # Optional: Set nixpkgs.
        # If unset, the nixpkgs input of extra-container flake is used
        nixpkgs = inputs.nixpkgs;

        # Set this to disable `nix run` support
        # addRunner = false;

        config = {
          containers.demo = {
            extra.addressPrefix = "10.250.0";

            # In Nixpkgs > 22.11 (currently this means unstable), `specialArgs` is available as an option.
            # It allows you to add module arguments that are evaluated outside the module system,
            # meaning you are allowed to use them in e.g. `imports` without causing infinite recursion.
            # specialArgs = { inherit inputs; };

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
        };
      };
    });
}
