{
  buildNpmPackage,
  fetchurl,
  lib,
  makeWrapper,
  nodejs,
  stdenvNoCC,
}:
buildNpmPackage (finalAttrs: {
  pname = "postplan";
  version = "0.0.4";
  src = stdenvNoCC.mkDerivation {
    pname = "postplan-source";
    inherit (finalAttrs) version;
    src = fetchurl {
      url = "https://registry.npmjs.org/postplan/-/postplan-${finalAttrs.version}.tgz";
      hash = "sha512-ctOrqRP+MhkhbUi9xCPO8k9lYLbwzWs7IfKnBy1nTiFeLtWVLntWdvII4kIhtNJSioa+b4nOx/8+qAYN2aBUvg==";
    };

    installPhase = ''
      runHook preInstall
      mkdir -p "$out"
      cp -R . "$out/"
      cp ${./package-lock.json} "$out/package-lock.json"
      runHook postInstall
    '';
  };

  npmDepsHash = "sha256-OuvS2ojMw2Sn6GC0FzGm2MqXrW1ZIeg0z7Ci9pgtNqE=";
  dontNpmBuild = true;
  nativeBuildInputs = [ makeWrapper ];

  postInstall = ''
    makeWrapper ${nodejs}/bin/node "$out/bin/postplan-server" \
      --add-flags "$out/lib/node_modules/postplan/src/server.js"
  '';

  meta = {
    mainProgram = "postplan";
    description = "PostPlan HTML draft publishing with Authentik and local storage";
    homepage = "https://www.npmjs.com/package/postplan";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
  };
})
