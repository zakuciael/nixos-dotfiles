final: prev: {
  httpie-desktop = let
    inherit (prev) fetchurl appimageTools;

    pname = "httpie-desktop";
    version = "2024.1.2";
    name = "${pname}-${version}";

    src = fetchurl {
      url = "https://github.com/httpie/desktop/releases/download/v${version}/HTTPie-${version}.AppImage";
      sha256 = "sha256-OOP1l7J2BgO3nOPSipxfwfN/lOUsl80UzYMBosyBHrM=";
    };

    contents = appimageTools.extractType2 {inherit name src;};
  in
    appimageTools.wrapType2 rec {
      inherit name src;

      extraInstallCommands = ''
        mv $out/bin/${name} $out/bin/${pname}
        install -m 444 -D ${contents}/httpie.desktop $out/share/applications/${pname}.desktop

        install -m 444 -D ${contents}/httpie.png $out/share/icons/hicolor/512x512/apps/httpie.png

        substituteInPlace $out/share/applications/${pname}.desktop \
         --replace 'Exec=AppRun --no-sandbox %U' 'Exec=${pname} %U'
      '';

      meta = with prev.lib; {
        description = "Cross-platform API testing client for humans. Painlessly test REST, GraphQL, and HTTP APIs";
        homepage = "https://github.com/httpie/desktop";
        license = licenses.unfree;
        maintainers = with maintainers; [zakuciael];
        mainProgram = "httpie-desktop";
        platforms = ["x86_64-linux"];
      };
    };
}
