{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    types
    optionalAttrs
    imap0
    ;
  inherit (lib.my.utils) findLayoutConfig;

  cfg = config.modules.desktop.sddm;
  layoutCfg = config.modules.hardware.layout;

  transformMap = {
    normal = "Normal";
    left = "Rotated90";
    right = "Rotated270";
  };

  mainLayout = findLayoutConfig config ({ name, ... }: name == "main");

  shouldGenerateKwinConfig = cfg.compositor == "kwin" && layoutCfg.enable && mainLayout != null;

  # Layout data baked in at eval time; EDID fields are added at runtime.
  layoutData = imap0 (
    _: layout:
    {
      connectorName = layout.monitor.wayland;
      isMain = layout.name == "main";
    }
    // optionalAttrs (layout.scale != null) { inherit (layout) scale; }
    // optionalAttrs (layout.rotate != null) { transform = transformMap.${layout.rotate}; }
  ) layoutCfg.layout;

  # Reads EDID from sysfs, computes MD5 hash and parses the identifier in the
  # exact format KWin's Edid class produces (src/utils/edid.cpp):
  #   "<PNP_ID> <product> <serial> <week> <manufacture_year> <model_year>"
  # Writes the resulting kwinoutputconfig.json before SDDM starts.
  kwinOutputConfigScript = pkgs.writeScript "generate-kwin-output-config" ''
    #!${pkgs.python3}/bin/python3
    import glob, grp, hashlib, json, os, pwd, struct

    LAYOUT = json.loads('${builtins.toJSON layoutData}')

    def parse_pnp_id(data):
        b0, b1 = data[8], data[9]
        return (
            chr(((b0 >> 2) & 0x1f) + ord('A') - 1) +
            chr((((b0 & 0x3) << 3) | ((b1 >> 5) & 0x7)) + ord('A') - 1) +
            chr((b1 & 0x1f) + ord('A') - 1)
        )

    def read_edid(connector):
        for path in glob.glob(f'/sys/class/drm/card*-{connector}/edid'):
            try:
                with open(path, 'rb') as f:
                    data = f.read()
                if data:
                    return data
            except OSError:
                continue
        return None

    def edid_fields(data):
        md5 = hashlib.md5(data).hexdigest()
        manufacturer = parse_pnp_id(data)
        product = struct.unpack_from('<H', data, 10)[0]
        serial = struct.unpack_from('<I', data, 12)[0]
        week, year_raw = data[16], data[17]
        if week == 0xFF:
            manufacture_week, manufacture_year, model_year = 0, 0, year_raw + 1990
        else:
            manufacture_week, manufacture_year, model_year = week, year_raw + 1990, 0
        identifier = f"{manufacturer} {product} {serial} {manufacture_week} {manufacture_year} {model_year}"
        return identifier, md5

    outputs, setups_outputs = [], []
    for i, entry in enumerate(LAYOUT):
        out = {k: entry[k] for k in ('connectorName', 'scale', 'transform') if k in entry}
        edid_data = read_edid(entry['connectorName'])
        if edid_data and len(edid_data) >= 18:
            out['edidIdentifier'], out['edidHash'] = edid_fields(edid_data)
        outputs.append(out)
        setups_outputs.append({
            'enabled': entry['isMain'],
            'outputIndex': i,
            'position': {'x': 0, 'y': 0},
            'priority': 1 if entry['isMain'] else 0,
            "replicationSource": "",
        })

    import subprocess, sys

    CHATTR = '${pkgs.e2fsprogs}/bin/chattr'

    config_dir = '/var/lib/sddm/.config'
    config_file = f'{config_dir}/kwinoutputconfig.json'
    os.makedirs(config_dir, exist_ok=True)

    # Drop immutable flag so we can (over)write on rebuilds.
    subprocess.run([CHATTR, '-i', config_file], capture_output=True)

    result = [
        {'name': 'outputs', 'data': outputs},
        {'name': 'setups', 'data': [{'lidClosed': False, 'outputs': setups_outputs}]},
    ]
    with open(config_file, 'w') as f:
        json.dump(result, f)

    try:
        uid = pwd.getpwnam('sddm').pw_uid
        gid = grp.getgrnam('sddm').gr_gid
        os.chown(config_dir, uid, gid)
        os.chown(config_file, uid, gid)
    except KeyError:
        pass

    # Make the file immutable so KWin's atomic rename cannot replace it.
    subprocess.run([CHATTR, '+i', config_file], check=True)
  '';
in
{
  options.modules.desktop.sddm = {
    enable = mkEnableOption "SDDM as a display manager";
    compositor = mkOption {
      description = "Wayland compositor to use";
      type = types.enum [
        "kwin"
        "weston"
      ];
      default = "weston";
    };
  };

  config = mkIf cfg.enable {
    services.displayManager = {
      sddm = {
        enable = true;
        wayland = {
          enable = true;
          inherit (cfg) compositor;
        };
        autoNumlock = true;
      };
    };

    systemd.services.sddm-kwin-output-config = mkIf shouldGenerateKwinConfig {
      description = "Generate KWin output config for SDDM with EDID data";
      before = [ "display-manager.service" ];
      wantedBy = [ "display-manager.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = kwinOutputConfigScript;
      };
    };
  };
}
