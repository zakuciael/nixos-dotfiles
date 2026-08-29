{ lib, ... }:
lib.singleton (
  final: prev:
  let
    inherit (final) rustPlatform;

    t3code-unwrapped = prev.t3code.unwrapped.overrideAttrs (
      finalAttrs: oldAttrs: {
        version = "0.0.36";

        src = oldAttrs.src.override {
          tag = "v${finalAttrs.version}";
          hash = "sha256-Usiwzy3ITTc8c3NGk898p0PqaI887n6sW0a77YY5ngw=";
        };

        pnpmDeps = oldAttrs.pnpmDeps.override {
          inherit (finalAttrs) version src;
          hash = "sha256-y/sJIluwbn65APmJ2p07FK1ScXpetCloTHtQzZMchDU=";
        };

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
