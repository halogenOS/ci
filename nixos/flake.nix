{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-25.11";
    foundrix = {
      url = "git+https://codeberg.org/xdevs23/foundrix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ci = {
      url = "github:halogenOS/ci";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      foundrix,
      ci,
      ...
    }@flakeArgs:
    let
      lib = nixpkgs.lib;
      foundrixLib = foundrix.lib;
      forAllSystems = lib.genAttrs lib.systems.flakeExposed;
    in
    foundrix.nixosModules.pluggedInTo flakeArgs rec {
      nixosConfigurations = {
        xos-builder = lib.nixosSystem {
          specialArgs = self.nixosModules.foundrixSpecialArgs;
          modules = [
            ci.nixosModules.buildkite
            ./configuration.nix
          ];
        };
      }
      // foundrixLib.deviceFramework.mkDeviceSpecificConfigurations {
        # Add your devices here, e.g.:
        # my-server = {
        #   nixosConfiguration = nixosConfigurations.xos-builder;
        #   deviceConfiguration = ./devices/my-server;
        #   platformModule = foundrix.nixosModules.hardware.platform.x86_64;
        # };
      };
      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt);
    };
}
