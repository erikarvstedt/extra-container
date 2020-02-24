{ stdenv, lib }:

stdenv.mkDerivation rec {
  name = "extra-container-${version}";
  version = "0.3";

  buildCommand = ''
    install -D ${./extra-container} $out/bin/extra-container
    patchShebangs $out/bin
    sed -i 's|evalConfig=.*|evalConfig=${./eval-config.nix}|' $out/bin/extra-container
  '';

  meta = with lib; {
    description = "Run declarative containers without full system rebuilds";
    homepage = https://github.com/erikarvstedt/extra-container;
    license = licenses.mit;
    maintainers = [ maintainers.earvstedt ];
  };
}
