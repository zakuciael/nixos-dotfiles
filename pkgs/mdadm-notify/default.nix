{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  makeWrapper,
  libnotify,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  name = "mdadm-notify";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "daenney";
    repo = "mdadm-notify";
    tag = "v${finalAttrs.version}";
    hash = "sha256-Ahv5ioCzAaPIo7Gu88x2OeRPNzEMLN2de5FuC1wg0LE=";
  };

  nativeBuildInputs = [
    makeWrapper
  ];

  buildInputs = [
    libnotify
  ];

  installPhase = ''
    install -dm755 $out/bin
    cp $src/mdadm-notify $out/bin/mdadm-notify
    wrapProgram $out/bin/mdadm-notify --prefix PATH : '${lib.makeBinPath finalAttrs.buildInputs}'
  '';

  meta = {
    description = "Send mdadm notifications to the desktop";
    license = lib.licenses.gpl3;
    maintainers = [ ];
    platforms = lib.platforms.linux;
    mainProgram = "mdadm-notify";
  };
})
