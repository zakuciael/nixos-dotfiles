{
  # keep-sorted start
  expat,
  fetchurl,
  fsnotifier,
  jetbrains,
  jetbrains-libdbm,
  lib,
  libxcrypt-legacy,
  libxml2,
  openssl,
  python3,
  stdenv,
  xz,
  # keep-sorted end
}:
let
  system = stdenv.hostPlatform.system;
  # update-script-start: urls
  urls = {
    x86_64-linux = {
      url = "https://download.jetbrains.com/rustrover/RustRover-2026.3.1.tar.gz";
      hash = "sha256-MXBXmDczsIYw2LcFaZrgCaI7a4ITrN9wdbERJZj9iww=";
    };
    aarch64-linux = {
      url = "https://download.jetbrains.com/rustrover/RustRover-2026.3.1-aarch64.tar.gz";
      hash = "sha256-+XoFaMURDZQmtDxhLGqYbqoqcGSct8oufxaNTbjW5W0=";
    };
    aarch64-darwin = {
      url = "https://download.jetbrains.com/rustrover/RustRover-2026.3.1-aarch64.dmg";
      hash = "sha256-Bf0P6VXfKRxneaL0pADz4lWstw6ePFA5rXoCmYxFALg=";
    };
  };
  # update-script-end: urls
in
jetbrains.mkJetBrainsProduct {
  inherit jetbrains-libdbm fsnotifier;

  pname = "rust-rover";

  wmClass = "jetbrains-rustrover";
  product = "RustRover";

  # update-script-start: version
  version = "2026.3.1";
  buildNumber = "263.7307.313";
  # update-script-end: version

  src = fetchurl (urls.${system} or (throw "Unsupported system: ${system}"));

  # the jdk is bundled on Darwin.
  jdk =
    if lib.meta.availableOn stdenv.hostPlatform jetbrains.jdk-no-jcef then
      jetbrains.jdk-no-jcef
    else
      null;

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [ jetbrains.sharedLibsHook ];

  buildInputs =
    lib.optionals stdenv.hostPlatform.isLinux [
      # keep-sorted start
      libxcrypt-legacy
      openssl
      python3
      # keep-sorted end
    ]
    ++ lib.optionals (stdenv.hostPlatform.isLinux && stdenv.hostPlatform.isAarch) [
      # keep-sorted start
      expat
      libxml2
      xz
      # keep-sorted end
    ];

  # NOTE: meta attrs are used for the Linux desktop entries and may cause rebuilds when changed
  meta = {
    homepage = "https://www.jetbrains.com/rust/";
    description = "Rust IDE from JetBrains";
    longDescription = "Rust IDE from JetBrains";
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
