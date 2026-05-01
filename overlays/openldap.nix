{ lib, ... }:
lib.singleton (
  _: prev: {
    # FIXME: Remove when any of those issues get resolved:
    # https://github.com/NixOS/nixpkgs/issues/513245
    # https://github.com/NixOS/nixpkgs/issues/514113
    openldap = prev.openldap.overrideAttrs {
      doCheck = false;
    };
  }
)
