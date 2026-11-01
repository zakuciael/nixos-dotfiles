{ lib, ... }:
# Writable discord_voice staging so background blur / virtual backgrounds work.
# Port of https://github.com/NixOS/nixpkgs/pull/535418
lib.singleton (
  final: prev:
  let
    inherit (final) writeShellScript;

    # Stable Discord binaryName; config dir is its lowercased form.
    binaryName = "Discord";

    mkBlurStageModules =
      {
        version,
        moduleVersions,
      }:
      writeShellScript "discord-stage-modules" ''
        store_modules="$1"
        config_dir="''${DISCORD_USER_DATA_DIR-''${XDG_CONFIG_HOME:-$HOME/.config}}/${lib.toLower binaryName}"
        modules_dir="$config_dir/${version}/modules"
        rm -rf "$modules_dir"
        mkdir -p "$modules_dir"
        for m in ${lib.concatStringsSep " " (lib.attrNames moduleVersions)}; do
          if [ "$m" = "discord_voice" ]; then
            # discord_voice bundles MediaPipe selfie-segmentation `.tflite`
            # models that the native voice engine opens read-write (O_RDWR).
            # A store symlink makes that open fail with EACCES, so blur /
            # virtual backgrounds render a black camera image. Stage a
            # writable copy once per version, then symlink to it.
            voice_copy="$config_dir/${version}/modules-writable/discord_voice"
            if [ ! -e "$voice_copy/.nix-staged" ]; then
              rm -rf "$voice_copy"
              mkdir -p "$voice_copy"
              cp -RL "$store_modules/$m/." "$voice_copy/"
              chmod -R u+w "$voice_copy"
              : > "$voice_copy/.nix-staged"
            fi
            ln -sn "$voice_copy" "$modules_dir/$m"
          else
            ln -sn "$store_modules/$m" "$modules_dir/$m"
          fi
        done
        echo '${builtins.toJSON (lib.mapAttrs (_: mod: { installedVersion = mod; }) moduleVersions)}' \
          > "$modules_dir/installed.json"
      '';

    applyBlurFix =
      pkg:
      let
        unwrapped = pkg.unwrappedDiscord or pkg;
        stageModules = mkBlurStageModules {
          inherit (unwrapped) version;
          inherit (pkg.passthru) moduleVersions;
        };
        # stageModules lives on both the drv attr (used by wrapProgram via
        # finalAttrs) and passthru (what `drv.stageModules` returns), so both
        # must be updated.
        patchedUnwrapped = unwrapped.overrideAttrs (old: {
          inherit stageModules;
          passthru = (old.passthru or { }) // {
            inherit stageModules;
          };
        });
      in
      if pkg.passthru ? fhsenv then
        (pkg.override { unwrappedDiscord = patchedUnwrapped; }).overrideAttrs (old: {
          passthru = old.passthru // {
            inherit stageModules;
            unwrappedDiscord = patchedUnwrapped;
          };
        })
      else
        patchedUnwrapped;
  in
  {
    # Re-wrap so `pkgs.discord.override { withOpenASAR = true; ... }` still works.
    discord = lib.makeOverridable (args: applyBlurFix (prev.discord.override args)) { };
  }
)
