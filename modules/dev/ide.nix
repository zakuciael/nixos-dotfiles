{
  config,
  lib,
  pkgs,
  username,
  ...
}:
with lib;
with lib.my; let
  cfg = config.modules.dev.ides;

  availableIdes = builtins.listToAttrs (
    builtins.map (value: {
      name = value.pname;
      inherit value;
    })
    (with pkgs.jetbrains; [
      clion
      datagrip
      dataspell
      gateway
      goland
      idea-community
      idea-ultimate
      mps
      phpstorm
      pycharm-community
      pycharm-professional
      rider
      ruby-mine
      rust-rover
      webstorm
    ])
  );
  installedIDEs = builtins.map (name: availableIdes.${name} or availableIdes."${name}-with-plugins") cfg;
in {
  options.modules.dev.ides = mkOption {
    description = "A list of JetBrains IDEs names to install";
    example = ["rust-rover" "webstorm"];
    default = [];
    type = with types; listOf (enum (builtins.map (name: builtins.replaceStrings ["-with-plugins"] [""] name) (builtins.attrNames availableIdes)));
  };

  config = mkIf (cfg != []) {
    home-manager.users.${username} = {
      home = {
        packages = installedIDEs;

        file = builtins.listToAttrs (builtins.map (ide: {
            name = ".local/share/JetBrains/apps/${ide.pname}";
            value = {
              source = "${ide}/${ide.pname}";
            };
          })
          installedIDEs);
      };
    };
  };
}
