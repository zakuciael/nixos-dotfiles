# Adds fix for Krisp module
# Modified version of this PR: https://github.com/NixOS/nixpkgs/pull/506089
{ lib, ... }:
{
  updateScript = "overlays/discord/update.py";

  overlays = lib.singleton (
    final: _:
    let
      inherit (final)
        callPackage
        fetchurl
        discord
        discord-ptb
        discord-canary
        discord-development
        ;

      variants = {
        discord = rec {
          branch = "stable";
          binaryName = desktopName;
          desktopName = "Discord";
          self = discord;
        };
        discord-ptb = {
          branch = "ptb";
          binaryName = "DiscordPTB";
          desktopName = "Discord PTB";
          self = discord-ptb;
        };
        discord-canary = {
          branch = "canary";
          binaryName = "DiscordCanary";
          desktopName = "Discord Canary";
          self = discord-canary;
        };
        discord-development = {
          branch = "development";
          binaryName = "DiscordDevelopment";
          desktopName = "Discord Development";
          self = discord-development;
        };
      };

      meta = {
        description = "All-in-one voice and text chat for gamers";
        downloadPage = "https://discordapp.com/download";
        homepage = "https://discordapp.com/";
        license = lib.licenses.unfree;
        mainProgram = "discord";
        maintainers = with lib.maintainers; [
          artturin
          FlameFlag
          infinidoge
          jopejoe1
          Scrumplex
        ];
        platforms = [ "x86_64-linux" ];
        sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
      };

      sources = lib.importJSON ./sources.json;
    in
    lib.genAttrs [ "discord" "discord-ptb" "discord-canary" "discord-development" ] (
      pname:
      let
        args = variants.${pname};
        source = sources."linux-${args.branch}";
        krispSource = source.modules.discord_krisp or null;
      in
      callPackage ./builder/linux.nix (
        (lib.removeAttrs args [ "branch" ])
        // {
          inherit pname source;
          meta = meta // {
            mainProgram = args.binaryName;
          };
        }
        // lib.optionalAttrs (krispSource != null) {
          krispSrc = fetchurl { inherit (krispSource) url sha256; };
        }
      )
    )
  );
}
