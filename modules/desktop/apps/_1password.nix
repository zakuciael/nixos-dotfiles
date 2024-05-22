{
  config,
  lib,
  pkgs,
  inputs,
  username,
  desktop,
  ...
}:
with lib;
with lib.my; {
  programs = {
    _1password.enable = true;
    _1password-gui = {
      enable = true;
      polkitPolicyOwners = [username];
    };

    fish.interactiveShellInit = ''
      source /home/${username}/.config/op/plugins.sh
    '';
  };

  environment.systemPackages = [inputs.age-plugin-op.default];

  modules.desktop.wm.${desktop}.autostartPrograms = [
    "${pkgs._1password-gui}/bin/1password"
  ];

  home-manager.users.${username}.programs = {
    git = mkIf (config.modules.dev.git.enable) {
      extraConfig = {
        commit.gpgsign = true;
        gpg.format = "ssh";
        gpg.ssh.program = "${pkgs._1password-gui}/bin/op-ssh-sign";
        user.signingkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEcrcFZPwdfoZb0ZP3SUr/ZgN6Hycpk57Ky1UMmPbAg8";
      };
    };

    ssh = {
      enable = true;
      extraConfig = ''
        Host *
            IdentityAgent ~/.1password/agent.sock
      '';
    };
  };
}
