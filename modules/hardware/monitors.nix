{
  pkgs,
  lib,
  config,
  ...
}:
with lib;
with lib.my; let
  cfg = config.modules.hardware.monitors;
  xrandrOptions = {
    output = mkOption {
      type = types.str;
      example = "DVI-0";
      description = lib.mdDoc ''
        The output name of the monitor, as shown by
        {manpage}`xrandr(1)` invoked without arguments.
      '';
    };

    primary = mkOption {
      type = types.bool;
      default = false;
      description = lib.mdDoc ''
        Whether this head is treated as the primary monitor,
      '';
    };

    monitorConfig = mkOption {
      type = types.lines;
      default = "";
      example = ''
        DisplaySize 408 306
        Option "DPMS" "false"
      '';
      description = lib.mdDoc ''
        Extra lines to append to the `Monitor` section
        verbatim. Available options are documented in the MONITOR section in
        {manpage}`xorg.conf(5)`.
      '';
    };
  };
  heads = let
    mkHead = num: config: {
      name = "multihead${toString num}";
      inherit config;
    };
  in
    imap1 mkHead cfg.layout;
  deviceSection = let
    monitors = forEach heads (h: ''
      Option "monitor-${h.config.output}" "${h.name}"
    '');
  in
    concatStrings monitors;
  monitorSections = let
    mkMonitor = previous: current:
      singleton {
        inherit (current) name;
        value = ''
          Section "Monitor"
            Identifier "${current.name}"
            ${optionalString (current.config.primary) ''Option "Primary" "true"''}
          ${indent current.config.monitorConfig}
          EndSection
        '';
      }
      ++ previous;
    monitors = reverseList (foldl mkMonitor [] heads);
  in
    concatMapStrings (getAttr "value") monitors;
  prefixStringLines = prefix: str:
    concatMapStringsSep "\n" (line: prefix + line) (splitString "\n" str);

  indent = prefixStringLines "  ";
in {
  options.modules.hardware.monitors = {
    enable = mkEnableOption "Enable X server monitor layout configuration";
    layout = mkOption {
      type = with types;
        listOf (coercedTo str (output: {
          inherit output;
        }) (submodule {options = xrandrOptions;}));
      # Set primary to true for the first head if no other has been set
      # primary already.
      apply = heads: let
        hasPrimary = any (x: x.primary) heads;
        firstPrimary = head heads // {primary = true;};
        newHeads = singleton firstPrimary ++ tail heads;
      in
        if heads != [] && !hasPrimary
        then newHeads
        else heads;
      description = lib.mdDoc ''
        Monitor layout configuration, just specify a list of XRandR
        outputs. The individual elements should be either simple strings or
        an attribute set of output options.

        If the element is a string, it is denoting the physical output for a
        monitor, if it's an attribute set, you must at least provide the
        {option}`output` option.

        By default, the first monitor will be set as the primary monitor if
        none of the elements contain an option that has set
        {option}`primary` to `true`.

        ::: {.note}
        Only one monitor is allowed to be primary.
        :::
      '';
    };
  };

  config = mkIf (cfg.enable) {
    services.xserver = {
      inherit deviceSection;
      extraConfig = monitorSections;
      exportConfiguration = true;
    };
  };
}
