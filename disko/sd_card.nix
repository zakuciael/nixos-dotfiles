{
  device ? throw "device not set",
  ...
}:
{
  disko.devices = {
    disk.sd_card = {
      inherit device;

      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          shared = {
            size = "150G";
            content = {
              type = "filesystem";
              format = "exfat";
              extraArgs = [
                "-L"
                "shared"
              ];
            };
          };
          steamdeck = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              extraArgs = [
                "-L"
                "steamdeck"
              ];
            };
          };
        };
      };
    };
  };
}
