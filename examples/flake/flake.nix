# See how this flake is used in ./usage.sh
{
  inputs.extra-container.url = "github:erikarvstedt/extra-container";
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = { extra-container, ... }@inputs:
    extra-container.lib.eachSupportedSystem (system: {
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

            # `specialArgs` is available in nixpkgs > 22.11
            # This is useful for importing flakes from modules (see nixpkgs/lib/modules.nix).
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
