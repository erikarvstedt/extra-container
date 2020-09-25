{ stdenv, lib,
  pkgSrc ? lib.cleanSource ./. }:

stdenv.mkDerivation rec {
  name = "extra-container-${version}";
  version = "0.4";

  src = pkgSrc;

  buildCommand = ''
    install -D $src/extra-container $out/bin/extra-container
    patchShebangs $out/bin
    install $src/eval-config.nix -Dt $out/src
    sed -i "s|evalConfig=.*|evalConfig=$out/src/eval-config.nix|" $out/bin/extra-container
  '';

  meta = with lib; {
    description = "Run declarative containers without full system rebuilds";
    homepage = https://github.com/erikarvstedt/extra-container;
    license = licenses.mit;
    maintainers = [ maintainers.earvstedt ];
  };
}
