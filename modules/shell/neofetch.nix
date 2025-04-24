{
  config,
  lib,
  pkgs,
  dotfiles,
  username,
  ...
}:
let
  inherit (lib)
    mkIf
    mkEnableOption
    attrNames
    concatMapStringsSep
    length
    ;

  cfg = config.modules.shell.neofetch;
  imageFile = dotfiles.neofetch."nixos.png".source;
  templateFile = dotfiles.neofetch."config.conf".source;

  disks = attrNames config.fileSystems;
  lines = 20 + (length disks);
  lineHeight = 20;
  configFile = pkgs.runCommand "config.conf" { } ''
    substitute "${templateFile}" "$out" \
      --replace-fail "{{% DISK_SHOW %}}" "${concatMapStringsSep " " (disk: "'${disk}'") disks}" \
      --replace-fail "{{% IMAGE_SIZE %}}" "${builtins.toString (lines * lineHeight)}px" \
      --replace-fail "{{% IMAGE_SOURCE %}}" "${imageFile}"
  '';
  neofetchPkg = pkgs.neofetch.overrideAttrs {
    postInstall = ''
      wrapProgram $out/bin/neofetch \
        --prefix PATH : ${
          lib.makeBinPath (
            with pkgs;
            [
              pciutils
              chafa
              imagemagick
            ]
          )
        }
    '';
  };
in
{
  options.modules.shell.neofetch = {
    enable = mkEnableOption "Neofetch CLI";
  };

  config = mkIf (cfg.enable) {
    home-manager.users.${username} = {
      home.packages = [ neofetchPkg ];

      xdg.configFile."neofetch/config.conf".source = configFile;
    };
  };
}
