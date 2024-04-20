<!--suppress HtmlDeprecatedAttribute, CheckImageSize -->
<h2 align="center">
  <a href="https://github.com/zakuciael/nixos-dotfiles">
    <img alt="My NixOS Dotfiles" src="assets/nixos-logo.svg" width="150px" />
  </a>
  <br />
  My NixOS Dotfiles
</h2>

<h4 align="center">
    A repository containing configuration files for my NixOS machine.
</h4>
<br />


## Folder structure
> [!NOTE]
> The folder structure is work in progress. Do not assume anything about the stability of the path of the modules in this repository, yet.

```bash
.
├── hosts/ 
│   └── .../                     # Host-specific system configuration overrides
│       ├── configuration.nix 
│       ├── hardware.nix
│       └── networking.nix
├── lib/
│   ├── apps.nix                 # Exports a function that generates configuration for desktop apps
│   ├── hosts.nix                # Exports a function that generates host configuration
│   ├── imports.nix              # Exports a function that allows for recursive imports
│   └── default.nix              # Exports all functions together
├── modules/                     # System configurations wrapped in togglable modules
│   ├── desktop/
│   │   ├── apps/                # User apps with custom configurations
│   │   │   └── example.nix
│   │   ├── apps.nix             # No-config user apps
│   │   ├── sddm.nix             # SDDM configuration
│   │   └── hyprland.nix         # Hyprland configuration
│   ├── hardware/ 
│   │   ├── bootloader.nix       # GRUB2 bootloader configuration
│   │   ├── sound.nix            # Sound configuration
│   │   ├── amd.nix              # AMD GPU configuration
│   │   └── usb.nix              # USB storage configuration
│   ├── networking/
│   │   └── default.nix          # Networking configurations
│   ├── services/
│   │   ├── polkit.nix           # PolKit configuration
│   │   └── flatpak.nix          # Flatpak configuration
│   ├── shell/
│   │   └── fish.nix             # Fish shell configuration
│   └── dev/
│       ├── git.nix              # Git configuration
│       └── ide.nix              # Configurations for JetBrains IDEs
├── configuration.nix            # Base configuration for all hosts
├── shell.nix                    # Default dev shell
└── flake.nix                    # Flake configuration
```

## Credits
- Radosaw Ratyna ([@Wittano](https://github.com/Wittano)) - For huge inspiration on how to structure my config and a massive portion of the code in the `lib/` directory.
- Thomas Marchand ([@Th0rgal](https://github.com/Th0rgal)) - For the README logo, which you can find [here](https://github.com/NixOS/nixos-artwork/issues/50).
- Tyler Kelley ([@Zaney](https://gitlab.com/Zaney)) - For his [dotfiles](https://gitlab.com/Zaney/zaneyos) which inspired me on how I want my OS to look like.

## License
This project is distributed under the MIT License. 
See [LICENSE](LICENSE) for more information.