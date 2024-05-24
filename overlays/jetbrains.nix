{
  lib,
  system,
  ...
}:
with lib; {
  unstable = singleton (final: prev: {
    jetbrains =
      prev.jetbrains
      // {
        # Modified version of https://github.com/NixOS/nixpkgs/blob/master/pkgs/development/compilers/jetbrains-jdk/default.nix
        jdk = let
          cpu = prev.stdenv.hostPlatform.parsed.cpu.name;
          arch =
            {
              "aarch64-linux" = "aarch64";
              "x86_64-linux" = "x64";
            }
            .${system};
        in
          prev.openjdk21.overrideAttrs (old: rec {
            pname = "jetbrains-jdk-jcef";

            javaVersion = "21.0.3";
            build = "457";

            # To get the new tag:
            # git clone https://github.com/jetbrains/jetbrainsruntime
            # cd jetbrainsruntime
            # git reset --hard [revision]
            # git log --simplify-by-decoration --decorate=short --pretty=short | grep "jbr-" --color=never | cut -d "(" -f2 | cut -d ")" -f1 | awk '{print $2}' | sort -t "-" -k 2 -g | tail -n 1 | tr -d ","
            openjdkTag = "jbr-21.0.2+13";
            version = "${javaVersion}-b${build}";

            src = prev.fetchFromGitHub {
              owner = "JetBrains";
              repo = "JetBrainsRuntime";
              rev = "jb${version}";
              hash = "sha256-wL6Qd/SBU3W+mgzfxqfzxXmnvIi/IB2Bn8mqAK5iYq0=";
            };

            BOOT_JDK = prev.openjdk21.home;
            SOURCE_DATE_EPOCH = 1716466801;

            patches = [];
            configurePlatforms = ["build"];
            dontConfigure = true;

            buildPhase = ''
              runHook preBuild

              cp -r ${final.jetbrains.jcef} jcef_linux_${arch}

              sed \
                  -e "s/OPENJDK_TAG=.*/OPENJDK_TAG=${openjdkTag}/" \
                  -e "s/SOURCE_DATE_EPOCH=.*//" \
                  -e "s/export SOURCE_DATE_EPOCH//" \
                  -i jb/project/tools/common/scripts/common.sh
              sed -i "s/STATIC_CONF_ARGS/STATIC_CONF_ARGS \$configureFlags/" jb/project/tools/linux/scripts/mkimages_${arch}.sh
              sed \
                  -e "s/create_image_bundle \"jb/#/" \
                  -e "s/echo Creating /exit 0 #/" \
                  -i jb/project/tools/linux/scripts/mkimages_${arch}.sh

              patchShebangs .
              ./jb/project/tools/linux/scripts/mkimages_${arch}.sh ${build} jcef

              runHook postBuild
            '';

            installPhase = let
              buildType = "release";
              jbrsdkDir = "jbrsdk_jcef-${javaVersion}-linux-${arch}-b${build}";
            in
              ''
                runHook preInstall

                mv build/linux-${cpu}-server-${buildType}/images/jdk/man build/linux-${cpu}-server-${buildType}/images/${jbrsdkDir}
                rm -rf build/linux-${cpu}-server-${buildType}/images/jdk
                mv build/linux-${cpu}-server-${buildType}/images/${jbrsdkDir} build/linux-${cpu}-server-${buildType}/images/jdk
              ''
              + old.installPhase
              + "runHook postInstall";

            postInstall = ''
              chmod +x $out/lib/openjdk/lib/chrome-sandbox
            '';

            postFixup = ''
              # Build the set of output library directories to rpath against
              LIBDIRS="${lib.makeLibraryPath (with prev; [
                xorg.libXdamage
                xorg.libXxf86vm
                xorg.libXrandr
                xorg.libXi
                xorg.libXcursor
                xorg.libXrender
                xorg.libX11
                xorg.libXext
                xorg.libxcb
                nss
                nspr
                libdrm
                mesa
                wayland
                udev
              ])}"
              for output in $outputs; do
                if [ "$output" = debug ]; then continue; fi
                LIBDIRS="$(find $(eval echo \$$output) -name \*.so\* -exec dirname {} \+ | sort -u | tr '\n' ':'):$LIBDIRS"
              done
              # Add the local library paths to remove dependencies on the bootstrap
              for output in $outputs; do
                if [ "$output" = debug ]; then continue; fi
                OUTPUTDIR=$(eval echo \$$output)
                BINLIBS=$(find $OUTPUTDIR/bin/ -type f; find $OUTPUTDIR -name \*.so\*)
                echo "$BINLIBS" | while read i; do
                  patchelf --set-rpath "$LIBDIRS:$(patchelf --print-rpath "$i")" "$i" || true
                  patchelf --shrink-rpath "$i" || true
                done
              done
            '';

            nativeBuildInputs = with prev; [git autoconf unzip rsync] ++ old.nativeBuildInputs;

            passthru =
              old.passthru
              // {
                home = "${final.jetbrains.jdk}/lib/openjdk";
              };

            meta = with lib; {
              description = "An OpenJDK fork to better support Jetbrains's products.";
              longDescription = ''
                JetBrains Runtime is a runtime environment for running IntelliJ Platform
                based products on Windows, Mac OS X, and Linux. JetBrains Runtime is
                based on OpenJDK project with some modifications. These modifications
                include: Subpixel Anti-Aliasing, enhanced font rendering on Linux, HiDPI
                support, ligatures, some fixes for native crashes not presented in
                official build, and other small enhancements.
                JetBrains Runtime is not a certified build of OpenJDK. Please, use at
                your own risk.
              '';
              homepage = "https://confluence.jetbrains.com/display/JBR/JetBrains+Runtime";
              inherit (prev.openjdk21.meta) license platforms mainProgram;
              maintainers = with maintainers; [zakuciael];

              broken = prev.stdenv.isDarwin;
            };
          });
      };
  });
}
