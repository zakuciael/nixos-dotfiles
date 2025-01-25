{
  lib,
  fetchurl,
  appimageTools,
}:
let
  pname = "httpie-desktop";
  version = "2024.1.2";

  src = fetchurl {
    url = "https://github.com/httpie/desktop/releases/download/v${version}/HTTPie-${version}.AppImage";
    sha256 = "sha256-OOP1l7J2BgO3nOPSipxfwfN/lOUsl80UzYMBosyBHrM=";
  };

  contents = appimageTools.extractType2 { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraInstallCommands = ''
    install -m 444 -D ${contents}/httpie.desktop $out/share/applications/httpie.desktop

    install -m 444 -D ${contents}/httpie.png $out/share/icons/hicolor/512x512/apps/httpie.png

    substituteInPlace $out/share/applications/httpie.desktop \
     --replace 'Exec=AppRun --no-sandbox %U' 'Exec=${pname} %U'
  '';

  meta = with lib; {
    description = "Cross-platform API testing client for humans. Painlessly test REST, GraphQL, and HTTP APIs";
    homepage = "https://github.com/httpie/desktop";
    license = licenses.unfree;
    maintainers = [ ];
    mainProgram = "httpie-desktop";
    platforms = [ "x86_64-linux" ];
  };
}
