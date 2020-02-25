{ stdenv, lib, nixos-container }:

stdenv.mkDerivation rec {
  name = "extra-container-${version}";
  version = "0.3";

  buildCommand = ''
    install -D ${./extra-container} $out/bin/extra-container
    patchShebangs $out/bin
    # We expect nix-build to be in PATH
    scriptPath="export PATH=${lib.makeBinPath [ nixos-container ]}:\$PATH"
    sed -i "2i$scriptPath" $out/bin/extra-container
  '';

  meta = with lib; {
    description = "Run declarative containers without full system rebuilds";
    homepage = https://github.com/erikarvstedt/extra-container;
    license = licenses.mit;
    maintainers = [ maintainers.earvstedt ];
  };
}
