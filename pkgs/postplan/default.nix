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
  version = "0.0.5";
  src = stdenvNoCC.mkDerivation {
    pname = "postplan-source";
    inherit (finalAttrs) version;
    src = fetchurl {
      url = "https://registry.npmjs.org/postplan/-/postplan-${finalAttrs.version}.tgz";
      hash = "sha512-b23n1iJGJgFON4v0mNsqUungKhonqgQCejVFFWEsmwzXiyP0CV+8D92kLfnTCUjPIKQfbHauJGs+5/vezpPd2A==";
    };

    installPhase = ''
      runHook preInstall
      mkdir -p "$out"
      cp -R . "$out/"
      cp ${./package-lock.json} "$out/package-lock.json"
      runHook postInstall
    '';
  };

  npmDepsHash = "sha256-wfQjMjBtEos6wtzBdMBm+Mi6A8Fvdzoj/vcrf50Cacg=";
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
