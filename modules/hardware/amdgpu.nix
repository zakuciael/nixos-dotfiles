{
  config,
  lib,
  ...
}:
with lib;
with lib.my; let
  cfg = config.modules.hardware.amdgpu;
in {
  options.modules.hardware.amdgpu = {
    enable = mkEnableOption "AMD GPU drivers";
  };

  config = mkIf (cfg.enable) {
    services.xserver.videoDrivers = ["amdgpu"];
    boot.initrd.kernelModules = ["amdgpu"];

    hardware = {
      enableRedistributableFirmware = true;
      graphics = {
        enable = true;
        enable32Bit = true;
      };
    };
  };
}
