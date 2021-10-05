{ stdenv, lib, nixos-container, openssh, glibcLocales
, pkgSrc ? lib.cleanSource ./.
}:

stdenv.mkDerivation rec {
  pname = "extra-container";
  version = "0.8";

  src = pkgSrc;

  buildCommand = ''
    install -D $src/extra-container $out/bin/extra-container
    patchShebangs $out/bin
    share=$out/share/extra-container
    install $src/eval-config.nix -Dt $share

    # Use existing PATH for systemctl and machinectl
    scriptPath="export PATH=${lib.makeBinPath [ nixos-container openssh ]}:\$PATH"

    sed -i "
      s|evalConfig=.*|evalConfig=$share/eval-config.nix|
      s|LOCALE_ARCHIVE=.*|LOCALE_ARCHIVE=${glibcLocales}/lib/locale/locale-archive|
      2i$scriptPath
    " $out/bin/extra-container
  '';

  meta = with lib; {
    description = "Run declarative containers without full system rebuilds";
    homepage = https://github.com/erikarvstedt/extra-container;
    license = licenses.mit;
    platforms = platforms.linux;
    maintainers = [ maintainers.earvstedt ];
  };
}
