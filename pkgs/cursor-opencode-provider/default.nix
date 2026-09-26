{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
}:

buildNpmPackage (finalAttrs: {
  pname = "cursor-opencode-provider";
  version = "0.7.4";

  src = fetchFromGitHub {
    owner = "oakimov";
    repo = "cursor-opencode-provider";
    tag = "v${finalAttrs.version}";
    hash = "sha256-sLaJCaSqWZBdQ4kwF8p+4NDSPHIHQ6OcuEJpnHoYf38=";
  };

  # Upstream ships bun.lock; generate/refresh with:
  #   npm install --package-lock-only --ignore-scripts
  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsHash = "sha256-87XHRHZ5JS36JiWYAHtIEBl1znjjLQLDL7bZ2A/GlkU=";

  meta = {
    description = "Use Cursor subscription models from OpenCode via Cursor's Connect-RPC agent protocol";
    homepage = "https://github.com/oakimov/cursor-opencode-provider";
    changelog = "https://github.com/oakimov/cursor-opencode-provider/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
})
