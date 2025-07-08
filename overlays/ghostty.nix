{ lib, ... }:
lib.singleton (
  _: prev: {
    ghostty = prev.ghostty.overrideAttrs {
      preBuild = ''
        shopt -s globstar
        sed -i 's/^const xev = @import("xev");$/const xev = @import("xev").Epoll;/' **/*.zig
        shopt -u globstar
      '';
    };
  }
)
