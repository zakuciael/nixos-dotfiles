# Build in-tree amdgpu as an out-of-tree module so we can patch it without
# rebuilding the whole kernel. See: wiki.nixos.org/wiki/Linux_kernel
#
# Override the target kernel with:
#   amdgpu-steam-vr.override { kernel = config.boot.kernelPackages.kernel; }
{
  lib,
  stdenv,
  fetchpatch,
  linuxPackages_latest,
  kernel ? linuxPackages_latest.kernel,
}:

stdenv.mkDerivation {
  pname = "amdgpu-steam-vr";
  inherit (kernel) src version postPatch;

  # SteamVR async reprojection: drop CAP_SYS_NICE check for high-priority queues (unsupported).
  patches = [
    (fetchpatch {
      name = "cap_sys_nice_begone.patch";
      url = "https://github.com/Frogging-Family/community-patches/raw/master/linux61-tkg/cap_sys_nice_begone.mypatch";
      hash = "sha256-Y3a0+x2xvHsfLax/uwycdJf3xLxvVfkfDVqjkxNaYEo=";
    })
  ];

  hardeningDisable = [
    "pic"
    "format"
  ];
  nativeBuildInputs = kernel.moduleBuildDependencies;
  enableParallelBuilding = true;

  # commonMakeFlags provides cmd_sign=kmodigest so modules_install writes the .ko.cer
  # that aggregateModules expects (plain sign-file fails and leaves no certificate).
  makeFlags = kernel.commonMakeFlags ++ [
    "KBUILD_OUTPUT=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
    "DEPMOD=true"
    "INSTALL_MOD_STRIP=1"
    "INSTALL_MOD_PATH=${placeholder "out"}"
    "M=$(PWD)/drivers/gpu/drm/amd/amdgpu"
  ];

  buildFlags = [ "modules" ];
  installTargets = [ "modules_install" ];

  meta = {
    description = "AMD GPU kernel module (patched for SteamVR async reprojection)";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
}
