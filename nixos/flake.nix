{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-25.11";
    foundrix = {
      url = "git+https://codeberg.org/xdevs23/foundrix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ci = {
      url = "path:..";
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
    in
    foundrix.nixosModules.pluggedInTo flakeArgs {
      nixosConfigurations = {
        ci = lib.nixosSystem {
          specialArgs = self.nixosModules.foundrixSpecialArgs;
          modules = [
            ci.nixosModules.buildkite
            ./configuration.nix
          ];
        };
      };
    };
}
