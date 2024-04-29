{
  lib,
  stdenv,
  ...
}:
stdenv.mkDerivation {
  name = "nixos-blur-plymouth";
  src = ./src;

  installPhase = ''
    mkdir -p $out/share/plymouth/themes/nixos-blur

    cp -r * $out/share/plymouth/themes/nixos-blur

    chmod +x $out/share/plymouth/themes/nixos-blur/nixos-blur.plymouth
    chmod +x $out/share/plymouth/themes/nixos-blur/nixos-blur.script
  '';

  meta = with lib; {
    # Offical git website with source was gone. I had to move package into my repository
    # homepage = "https://git.gurkan.in/gurkan/nixos-blur-plymouth";
    description = "Blur plymouth theme created by gurkan";
    license = licenses.gpl3;
    maintainers = with maintainers; [zakuciael];
    platforms = platforms.linux;
  };
}
