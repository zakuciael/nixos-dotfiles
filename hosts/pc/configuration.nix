{
  config,
  pkgs,
  lib,
  system,
  inputs,
  ...
}: {
  imports = [./hardware.nix ./networking.nix];

  services.xserver.displayManager.setupCommands = ''
    ${pkgs.xorg.xrandr}/bin/xrandr \
      --output DisplayPort-0 --primary --crtc 0 --mode 1920x1080 --rate 144.00 --pos 1080x393 \
      --output DisplayPort-1 --crtc 1 --mode 1920x1080 --rate 60.00 --rotate left --pos 0x0 \
      --output HDMI-A-0 --crtc 2 --mode 1920x1080 --rate 60.00 --pos 3000x440
  '';

  services.autorandr = {
    enable = true;
    defaultTarget = "default";
    profiles = {
      "default" = {
        fingerprint = {
          "DisplayPort-0" = "00ffffffffffff0005e390255f2b0100211d0104a5361e783b9051a75553a028135054bfef00d1c081803168317c4568457c6168617c023a801871382d40582c4500202f2100001efc7e80887038124018203500202f2100001e000000fc003235393047340a202020202020000000fd001e92a0a021010a202020202020010302031ef14b0103051404131f12021190230907078301000065030c001000866f80a07038404030203500202f2100001efe5b80a07038354030203500202f2100001e011d007251d01e206e285500202f2100001eab22a0a050841a3030203600202f2100001a7c2e90a0601a1e4030203600202f2100001a00000000000000f9";
          "DisplayPort-1" = "00ffffffffffff0010acf3404c4e36420f1a0104a5331d783aebf5a656519c26105054a54b00714f8180a9c0d1c00101010101010101023a801871382d40582c4500fd1e1100001e000000ff00563247353136344242364e4c0a000000fc0044454c4c205032333137480a20000000fd00384c1e5311010a2020202020200047";
          "HDMI-A-0" = "00ffffffffffff0009d1e878010101012e1d010380301b782e79a5a85551a227105054a56b80d1c0b300a9c08180810081c001010101023a801871382d40582c4500dc0c1100001e000000ff0045544c424b3033353336534c30000000fd00324c1e5311000a202020202020000000fc0042656e51204757323238300a200132020322f14f901f04130312021101140607151605230907078301000065030c001000023a801871382d40582c4500dc0c1100001e011d8018711c1620582c2500dc0c1100009e011d007251d01e206e285500dc0c1100001e8c0ad08a20e02d10103e9600dc0c1100001800000000000000000000000000000000000000000081";
        };
        config = {
          "DisplayPort-0" = {
            enable = true;
            crtc = 0;
            primary = true;
            mode = "1920x1080";
            position = "1080x393";
            rate = "144.00";
          };
          "DisplayPort-1" = {
            enable = true;
            crtc = 1;
            mode = "1920x1080";
            position = "0x0";
            rate = "60.00";
            rotate = "left";
          };
          "HDMI-A-0" = {
            enable = true;
            crtc = 2;
            mode = "1920x1080";
            position = "3000x440";
            rate = "60.00";
          };
        };
      };
    };
  };

  modules = {
    hardware = {
      grub = {
        enable = true;
        theme = inputs.distro-grub-themes.packages.${system}.nixos-grub-theme;
      };
      sound.enable = true;
      amdgpu.enable = true;
      docker.enable = true;
      yubikey.enable = true;
    };
    desktop = {
      apps.enable = true;
      gnome.enable = true;
    };
  };
}
