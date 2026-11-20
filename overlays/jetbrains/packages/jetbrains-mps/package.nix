{
  # keep-sorted start
  fetchurl,
  fsnotifier,
  jetbrains,
  jetbrains-libdbm,
  lib,
  stdenv,
  # keep-sorted end
}:
let
  system = stdenv.hostPlatform.system;
  # update-script-start: urls
  urls = {
    x86_64-linux = {
      url = "https://download.jetbrains.com/mps/2026.2/MPS-2026.2.tar.gz";
      hash = "sha256-zgzyDheO/FoBS5Bm6ysvzlNKFkE4vz0a5eXRFyK/TPg=";
    };
    aarch64-linux = {
      url = "https://download.jetbrains.com/mps/2026.2/MPS-2026.2.tar.gz";
      hash = "sha256-zgzyDheO/FoBS5Bm6ysvzlNKFkE4vz0a5eXRFyK/TPg=";
    };
    aarch64-darwin = {
      url = "https://download.jetbrains.com/mps/2026.2/MPS-2026.2-macos-aarch64.dmg";
      hash = "sha256-O9Aa33zwTFHms0eKfxNwr331EQEu17h5AnVa0OKAbMU=";
    };
  };
  # update-script-end: urls
in
jetbrains.mkJetBrainsProduct {
  inherit jetbrains-libdbm fsnotifier;

  pname = "mps";

  wmClass = "jetbrains-MPS";
  product = "MPS";

  # update-script-start: version
  version = "2026.2";
  buildNumber = "262.11879.701";
  # update-script-end: version

  src = fetchurl (urls.${system} or (throw "Unsupported system: ${system}"));

  # the jdk is bundled on Darwin.
  jdk =
    if lib.meta.availableOn stdenv.hostPlatform jetbrains.jdk-no-jcef then
      jetbrains.jdk-no-jcef
    else
      null;

  # NOTE: meta attrs are used for the Linux desktop entries and may cause rebuilds when changed
  meta = {
    homepage = "https://www.jetbrains.com/mps/";
    description = "IDE for building domain-specific languages from JetBrains";
    longDescription = "A metaprogramming system which uses projectional editing which allows users to overcome the limits of language parsers, and build DSL editors, such as ones with tables and diagrams.";
    maintainers = [ ];
    teams = [ lib.teams.jetbrains ];
    license = lib.licenses.unfree;
    sourceProvenance =
      if stdenv.hostPlatform.isDarwin then
        [ lib.sourceTypes.binaryNativeCode ]
      else
        [ lib.sourceTypes.binaryBytecode ];
  };
}
