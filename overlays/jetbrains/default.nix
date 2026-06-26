{ inputs, lib, ... }:
lib.singleton (
  final: prev:
  let
    inherit (final) callPackage stdenv python3;

    mkIdeWrapper =
      func: extras:
      lib.makeOverridable (
        {
          extraWrapperArgs ? [ ],
          vmopts ? null,
          forceWayland ? null,
        }:
        func (
          {
            mkJetBrainsProduct = lib.extendMkDerivation {
              constructDrv = mkJetBrainsProduct;

              extendDrvArgs = _: _: {
                inherit extraWrapperArgs forceWayland vmopts;
              };
            };
          }
          // extras
        )
      ) { };

    mkJetBrainsProduct =
      callPackage "${inputs.nixpkgs}/pkgs/applications/editors/jetbrains/builder/default.nix"
        {
          jdk = final.jetbrains.jdk;
          forceWayland = false;
          vmopts = null;
        };

    mkJetBrainsSource =
      callPackage "${inputs.nixpkgs}/pkgs/applications/editors/jetbrains/source/build.nix"
        { };

    mkSrcIde =
      path: extras:
      mkIdeWrapper (callPackage "${inputs.nixpkgs}/pkgs/applications/editors/jetbrains/${path}") (
        { inherit mkJetBrainsSource; } // extras
      );

    # The binary builds use the same libdbm and fsnotifier as the current idea-oss source build.
    mkBinIde =
      path: extras:
      mkIdeWrapper (callPackage "${inputs.nixpkgs}/pkgs/applications/editors/jetbrains/${path}") (
        { inherit (prev.jetbrains.idea-oss) libdbm fsnotifier; } // extras
      );

    # Common build overrides, fixes, etc.
    # TODO: These should eventually be moved outside of this file
    pyCharmCommonOverrides =
      _: previousAttrs:
      lib.optionalAttrs stdenv.hostPlatform.isLinux {
        buildInputs =
          with python3.pkgs;
          (previousAttrs.buildInputs or [ ])
          ++ [
            python3
            setuptools
          ];
        preInstall = ''
          echo "compiling cython debug speedups"
          if [[ -d plugins/python-ce ]]; then
              ${python3.interpreter} plugins/python-ce/helpers/pydev/setup_cython.py build_ext --inplace
          else
              ${python3.interpreter} plugins/python/helpers/pydev/setup_cython.py build_ext --inplace
          fi
        '';
        # See https://www.jetbrains.com/help/pycharm/2022.1/cython-speedups.html
      };
    patchSharedLibs = lib.optionalString stdenv.hostPlatform.isLinux ''
      ls -d \
        $out/*/bin/*/linux/*/lib/liblldb.so \
        $out/*/bin/*/linux/*/lib/python3.*/lib-dynload/* \
        $out/*/plugins/*/bin/*/linux/*/lib/liblldb.so \
        $out/*/plugins/*/bin/*/linux/*/lib/python3.*/lib-dynload/* |
      xargs patchelf \
        --replace-needed libssl.so.10 libssl.so \
        --replace-needed libssl.so.1.1 libssl.so \
        --replace-needed libcrypto.so.10 libcrypto.so \
        --replace-needed libcrypto.so.1.1 libcrypto.so \
        --replace-needed libcrypt.so.1 libcrypt.so \
        ${lib.optionalString stdenv.hostPlatform.isAarch "--replace-needed libxml2.so.2 libxml2.so"}
    '';
  in
  {
    jetbrains = prev.jetbrains // {
      clion = mkBinIde "ides/clion.nix" { inherit patchSharedLibs; };
      datagrip = mkBinIde "ides/datagrip.nix" { };
      dataspell = mkBinIde "ides/dataspell.nix" { };
      gateway = mkBinIde "ides/gateway.nix" { };
      goland = mkBinIde "ides/goland.nix" { };
      idea = mkBinIde "ides/idea.nix" { };
      mps = mkBinIde "ides/mps.nix" { };
      phpstorm = mkBinIde "ides/phpstorm.nix" { };
      pycharm = mkBinIde "ides/pycharm.nix" { inherit pyCharmCommonOverrides; };
      pycharm-oss = mkSrcIde "ides/pycharm-oss.nix" { inherit pyCharmCommonOverrides; };
      rider = mkBinIde "ides/rider.nix" { inherit patchSharedLibs; };
      ruby-mine = mkBinIde "ides/ruby-mine.nix" { };
      rust-rover = mkBinIde "ides/rust-rover.nix" { inherit patchSharedLibs; };
      webstorm = mkBinIde "ides/webstorm.nix" { };
    };
  }
)
