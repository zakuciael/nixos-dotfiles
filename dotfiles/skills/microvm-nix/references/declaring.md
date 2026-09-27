Upstream source: [doc/src/declaring.md](https://github.com/microvm-nix/microvm.nix/blob/f5dd93cd4305a43ae4e9977549cd0e0c08d2ef82/doc/src/declaring.md)

Modified excerpt from the upstream project; see [LICENSE](../LICENSE).

# Declaring NixOS MicroVMs

![Demo](https://github.com/microvm-nix/microvm.nix/blob/f5dd93cd4305a43ae4e9977549cd0e0c08d2ef82/doc/src/demo.gif)

microvm.nix creates virtual machine disk images and runner script
packages for the entries of the `nixosConfigurations` section of a
`flake.nix` file.

## The `microvm` module

To add MicroVM functionality, a NixOS system configuration is
augmented by importing this flake's `nixosModule.microvm`:

```nix
# Example flake.nix
{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  inputs.microvm.url = "github:microvm-nix/microvm.nix";
  inputs.microvm.inputs.nixpkgs.follows = "nixpkgs";

  outputs = { self, nixpkgs, microvm }: {
    # Example nixosConfigurations entry
    nixosConfigurations.my-microvm = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        # Include the microvm module
        microvm.nixosModules.microvm
        # Add more modules here
        {
          networking.hostName = "my-microvm";
          microvm.hypervisor = "cloud-hypervisor";
        }
      ];
    };
  };
}
```

To get you started quickly, a Flake template is included. Run `nix
flake init -t github:microvm-nix/microvm.nix` in a new project directory.
