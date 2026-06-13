{ lib, ... }:
lib.singleton (
  final: prev:
  let
    inherit (final) fetchFromGitHub;
  in
  {
    netbird = prev.netbird.overrideAttrs (prevAttrs: rec {
      version = "0.72.4";

      src = fetchFromGitHub {
        owner = "netbirdio";
        repo = "netbird";
        tag = "v${version}";
        hash = "sha256-YRXXuaqnQBLODcz/FNpIG9Ht+6VGRknE2Q6Q5ZaAIus=";
      };

      vendorHash = "sha256-6FN7l+e75Pw2+v0sktomlck+7daro1i6c4ZV53SRePI=";
    });
  }
)
