{ stdenv, lib, nixos-container ? null }:

stdenv.mkDerivation rec {
  name = "extra-container-${version}";
  version = "0.3";

  src = ./extra-container;
  dontUnpack = true;

  propagatedBuildInputs = [
    nixos-container
  ];

  installPhase = ''
    install -D ${./extra-container} $out/bin/extra-container
    patchShebangs $out/bin
  '' + lib.optionalString (nixos-container != null) ''
    substituteInPlace $out/bin/extra-container \
       --replace 'exec nixos-container' 'exec ${nixos-container}/bin/nixos-container'
  '';

  meta = with lib; {
    description = "Run declarative containers without full system rebuilds";
    homepage = https://github.com/erikarvstedt/extra-container;
    license = licenses.mit;
    maintainers = [ maintainers.earvstedt ];
  };
}
