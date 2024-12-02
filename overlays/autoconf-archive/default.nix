{lib, ...}:
with lib;
  singleton (final: prev: {
    # TODO: Remove when https://github.com/NixOS/nixpkgs/pull/355948 is merged into unstable branch
    autoconf-archive = prev.autoconf-archive.overrideAttrs (prevAttrs: {
      patches = [
        # cherry-picked changes from
        # https://git.savannah.gnu.org/gitweb/?p=autoconf-archive.git;a=commit;h=fadde164479a926d6b56dd693ded2a4c36ed89f0
        # can be removed on next release
        ./0001-ax_check_gl.m4-properly-quote-m4_fatal.patch
        ./0002-ax_check_glx.m4-properly-quote-m4_fatal.patch
        ./0003-ax_switch_flags.m4-properly-quote-m4_fatal.patch
      ];
    });
  })
