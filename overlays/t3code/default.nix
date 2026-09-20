{ lib, ... }:
lib.singleton (
  final: prev:
  let
    inherit (final) rustPlatform fetchurl runCommand;

    # Upstream 0.0.42's web build fetches SPDX license texts at build time
    # (scripts/lib/third-party-licenses.ts). Prefetch them so the sandbox build
    # can stay offline.
    spdxLicenseListRevision = "c4a7237ec8f4654e867546f9f409749300f1bf4c";
    spdxLicenseIds = [
      "Apache-2.0"
      "BSD-2-Clause"
      "BSD-3-Clause"
      "CC0-1.0"
      "ISC"
      "MIT"
      "Unlicense"
    ];
    spdxLicenseHashes = {
      "Apache-2.0" = "sha256-iyt7wmfXAL6UCFzSyDA+Atj4ODKLKnMQ3DqIQNPKErs=";
      "BSD-2-Clause" = "sha256-h2hDpwacR4mNECQyo1vjMqRXz3r/gJTMsYqj315jQJI=";
      "BSD-3-Clause" = "sha256-RXYFS3RBfUAh/9ovY7h/3lJ5Hj7ZTu7yznkwJRtDcwE=";
      "CC0-1.0" = "sha256-gdRg6RFSHhS1Ky/Y4Gl5Wscx6JhspYpdKUFdzAHqoSU=";
      "ISC" = "sha256-VJTDV7IdtsBt1r1r1J1ldZINPVNDQE5vVFkWPmjn5Yo=";
      "MIT" = "sha256-fuCJ3MxiW/GLCrHoDgxLysVYeIT1viXZATuK1sYd1Dk=";
      "Unlicense" = "sha256-itR5uQEH/xGJKbe09Fvk/axB/Aq0J6LEIbwwY52X4fs=";
    };
    spdxLicenseCache = runCommand "t3code-spdx-license-cache" { } ''
      mkdir -p "$out"
      ${lib.concatMapStringsSep "\n" (licenseId: ''
        cp ${fetchurl {
          url = "https://raw.githubusercontent.com/spdx/license-list-data/${spdxLicenseListRevision}/json/details/${licenseId}.json";
          hash = spdxLicenseHashes.${licenseId};
        }} "$out/${licenseId}.json"
      '') spdxLicenseIds}
    '';

    # Upstream 0.0.34+ builds a libsecret helper during `build:desktop` and
    # expects a newer Electron than nixpkgs-unstable's package pins. Mirror the
    # packaging deltas from nixpkgs master (electron_43, libsecret, pkg-config,
    # browser-secret install) while pinning the newer release here.
    t3code-unwrapped =
      (prev.t3code.unwrapped.override {
        electron_41 = final.electron_43;
      }).overrideAttrs
        (
          finalAttrs: oldAttrs: {
            version = "0.0.42";

            src = oldAttrs.src.override {
              tag = "v${finalAttrs.version}";
              hash = "sha256-YV86WqqpGQwjeovXB0IoE3f/o4IUC5DDVdBEdT4xzjc=";
            };

            pnpmDeps = oldAttrs.pnpmDeps.override {
              inherit (finalAttrs) version src;
              hash = "sha256-gEY2em9pNTC1EuVX0V3L/Wu1apZ+BKBXxALEcPQ/pwA=";
            };

            nativeBuildInputs =
              (oldAttrs.nativeBuildInputs or [ ])
              ++ lib.optionals final.stdenv.hostPlatform.isLinux [ final.pkg-config ];

            buildInputs =
              (oldAttrs.buildInputs or [ ])
              ++ lib.optionals final.stdenv.hostPlatform.isLinux [ final.libsecret ];

            postPatch =
              (oldAttrs.postPatch or "")
              + ''
                mkdir -p .generated/third-party-licenses/spdx/v3.28.0
                cp -r ${spdxLicenseCache}/. .generated/third-party-licenses/spdx/v3.28.0/
              '';

            # installPhase from nixpkgs-unstable does not yet ship the helper.
            postInstall =
              lib.optionalString final.stdenv.hostPlatform.isLinux ''
                install -Dm755 \
                  native/browser-secret/build/${final.stdenv.hostPlatform.node.arch}/t3-browser-secret \
                  "$out"/libexec/t3code/apps/desktop/prod-resources/browser-secret/t3-browser-secret
              ''
              + (oldAttrs.postInstall or "");

            passthru = oldAttrs.passthru // {
              # nix-update-script cannot drive this overlay (store-copied overlay paths
              # break nix-update --flake position mapping); use the local update.sh.
              updateScript = ./update.sh;
            };
          }
        );

    t3code-resource-monitor =
      (prev.t3code.resourceMonitor.override {
        inherit t3code-unwrapped;
      }).overrideAttrs
        (oldAttrs: rec {
          cargoHash = "sha256-5cmG2daM1bVOA23gjjoalbx0fEL1hmqV6WZov0sUZp8=";
          cargoDeps = rustPlatform.fetchCargoVendor {
            inherit (t3code-unwrapped) src;
            inherit (oldAttrs) pname;
            sourceRoot = "${t3code-unwrapped.src.name}/native/resource-monitor";
            hash = cargoHash;
          };
        });
  in
  {
    t3code = prev.t3code.override {
      inherit t3code-unwrapped t3code-resource-monitor;
    };
  }
)
