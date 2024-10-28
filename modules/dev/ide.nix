{
  config,
  lib,
  pkgs,
  unstable,
  username,
  ...
}:
with lib;
with lib.my; let
  cfg = config.modules.dev.ides;

  goland = unstable.jetbrains.goland.overrideAttrs (attrs: {
    postFixup =
      (attrs.postFixup or "")
      + optionalString pkgs.stdenv.isLinux ''
        if [ -f $out/goland/plugins/go-plugin/lib/dlv/linux/dlv ]; then
          rm $out/goland/plugins/go-plugin/lib/dlv/linux/dlv
        fi

        ln -s ${unstable.delve}/bin/dlv $out/goland/plugins/go-plugin/lib/dlv/linux/dlv
      '';
  });

  avaiableIdes = builtins.listToAttrs (
    builtins.map (value: {
      name = value.pname;
      inherit value;
    })
    (with unstable.jetbrains; [
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
  installedIDEs = builtins.map (name: avaiableIdes.${name}) cfg;
in {
  options.modules.dev.ides = mkOption {
    description = "A list of JetBrains IDEs names to install";
    example = ["rust-rover" "webstorm"];
    default = [];
    type = with types; listOf (enum (builtins.attrNames avaiableIdes));
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
