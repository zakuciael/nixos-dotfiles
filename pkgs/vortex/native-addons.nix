# Native N-API addons that need compilation because --ignore-scripts skips
# their install hooks (prebuild-install / node-gyp rebuild).
#
# Windows-only modules (crash-dump, winapi-bindings, native-errors) are no-ops on Linux.
# fomod-installer-native ships bundled prebuilds (prebuilds/linux-x64/).
# xxhash-addon, leveldown ship bundled prebuilds; no node-gyp needed at build time.
# protobufjs is pure JS; unrs-resolver ships @unrs/resolver-binding-linux-x64-gnu prebuilts.
#
# bsatk, ba2tk, esptk: C++ sources live in external git submodules not bundled in the
# npm tarball; prebuild-install also needs network — skip (non-fatal).
# loot: libloot only ships a Windows DLL in the npm package; no Linux .so — skip.
#
# The others need node-gyp compilation. pnpm rebuild <name> in v10 does not reliably
# find packages in the virtual store, so we locate each package under node_modules/.pnpm
# and invoke node-gyp directly via the package's own local node_modules/.bin.
# autogypi is run unconditionally before node-gyp — some addons (vortexmt, gamebryo-savegame,
# loot) need it to generate auto-top.gypi even when binding.gyp already exists.
{ lib }:
let
  addonNames = [
    "vortexmt"
    "diskusage"
    "drivelist"
    "bsdiff-node"
    "font-scanner"
    "gamebryo-savegame"
  ];
in
{
  inherit addonNames;

  # Compile each addon by finding it in the pnpm virtual store (depth 3 under
  # node_modules/.pnpm) and running its local node-gyp binary.  autogypi is run
  # first for addons that generate binding.gyp from a template.  Failures are
  # non-fatal so a broken addon doesn't abort the whole build.
  buildScript = ''
    # Shared node-gyp/autogypi hoisted by pnpm into the virtual store root; used as
    # fallback for packages that don't bundle their own (e.g. font-scanner, drivelist).
    _root="$(pwd)"
    _shared_node_gyp="$_root/node_modules/.pnpm/node_modules/.bin/node-gyp"
    _shared_autogypi="$_root/node_modules/.pnpm/node_modules/.bin/autogypi"

    for addon in ${lib.concatStringsSep " " addonNames}; do
      pkg_dir=$(find node_modules/.pnpm -maxdepth 3 -type d 2>/dev/null \
                  | grep "/node_modules/$addon$" | head -1)
      if [ -z "$pkg_dir" ]; then continue; fi
      pushd "$pkg_dir"
      autogypi="./node_modules/.bin/autogypi"
      node_gyp="./node_modules/.bin/node-gyp"
      [ ! -x "$autogypi" ] && [ -x "$_shared_autogypi" ] && autogypi="$_shared_autogypi"
      [ ! -x "$node_gyp" ] && [ -x "$_shared_node_gyp" ] && node_gyp="$_shared_node_gyp"
      # autogypi generates auto-top.gypi (and binding.gyp if absent); run it whenever present
      if [ -x "$autogypi" ]; then
        "$autogypi" 2>&1 || true
      fi
      if [ -f "binding.gyp" ] && [ -x "$node_gyp" ]; then
        "$node_gyp" rebuild 2>&1 || true
      fi
      popd
    done
  '';

  # Copy compiled build/ dirs from pnpm virtual store into the hoisted dist node_modules.
  # build/ sits at depth 4 from node_modules/.pnpm (…/<pkg>@ver/node_modules/<pkg>/build).
  copyToDistScript = lib.concatMapStringsSep "\n" (name: ''
    src=$(find node_modules/.pnpm -maxdepth 4 -path "*/${name}/build" -type d 2>/dev/null | head -1)
    if [ -n "$src" ] && [ -d "src/main/dist/node_modules/${name}" ]; then
      cp -r "$src" "src/main/dist/node_modules/${name}/"
    fi
  '') addonNames;
}
