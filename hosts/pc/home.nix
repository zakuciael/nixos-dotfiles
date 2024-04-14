{
  config,
  pkgs,
  lib,
  ...
}: {
  home = {
    stateVersion = "23.11";
    username = "zakuciael";
    homeDirectory = "/home/zakuciael";
    packages = with pkgs; [
      (import ../../scripts/fix_elgato.nix {inherit pkgs;})
    ];
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # TODO: Move to module
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # TODO: Move to separate module
  programs.git = {
    enable = true;
    userName = "Krzysztof Saczuk";
    userEmail = "me@krzysztofsaczuk.pl";
    extraConfig = {
      commit.gpgsign = true;
      gpg.format = "ssh";
      gpg.ssh.program = "${pkgs._1password-gui}/bin/op-ssh-sign";
      user.signingkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEcrcFZPwdfoZb0ZP3SUr/ZgN6Hycpk57Ky1UMmPbAg8";
    };
  };

  programs.ssh = let
    agentPath = "~/.1password/agent.sock";
  in {
    enable = true;
    extraConfig = ''
      Host *
          IdentityAgent ${agentPath}
    '';
  };
}
