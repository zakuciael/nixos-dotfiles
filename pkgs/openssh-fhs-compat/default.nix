{
  lib,
  symlinkJoin,
  writeShellScriptBin,
  openssh,
}:

# OpenSSH refuses ~/.ssh/config when it is a symlink into the Nix store and the
# process runs inside a user-namespace FHS env (buildFHSEnv / appimageTools):
# store paths appear owned by `nobody`, which fails StrictModes.
# Passing -F names the same file and skips only that ownership check.
let
  wrap =
    cmd:
    writeShellScriptBin cmd ''
      config="''${HOME}/.ssh/config"
      if [ -e "$config" ]; then
        exec ${openssh}/bin/${cmd} -F "$config" "$@"
      else
        exec ${openssh}/bin/${cmd} "$@"
      fi
    '';
in
symlinkJoin {
  name = "openssh-fhs-compat-${openssh.version}";
  paths = map wrap [
    "ssh"
    "scp"
    "sftp"
  ];
  meta = {
    description = "OpenSSH wrappers that pass -F ~/.ssh/config for FHS / bubblewrap envs";
    homepage = "https://www.openssh.com/";
    license = openssh.meta.license;
    platforms = openssh.meta.platforms;
    mainProgram = "ssh";
  };
}
