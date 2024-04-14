### Project folder structure
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