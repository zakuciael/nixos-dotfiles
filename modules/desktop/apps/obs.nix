{ pkgs, ... }:
{
  programs.obs-studio = {
    enable = true;
    enableVirtualCamera = true;

    plugins = with pkgs.obs-studio-plugins; [
      obs-pipewire-audio-capture
      obs-vaapi # optional AMD hardware acceleration
      obs-gstreamer
      obs-vkcapture
    ];
  };
}
