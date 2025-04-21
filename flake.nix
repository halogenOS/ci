{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
  };

  outputs = { nixpkgs, ... }:
    let
      forEachSystem = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed;
    in
    {
      packages = forEachSystem (system:
        let
          pkgs = import nixpkgs { inherit system; };
          lib = nixpkgs.lib;
        in {
          xos-buildkite-image =
          let nixosSystem = lib.nixosSystem {
            inherit system;
            modules = [
              ({ modulesPath, config, ... }: {
                imports = [
                  "${modulesPath}/virtualisation/docker-image.nix"
                  "${modulesPath}/installer/cd-dvd/channel.nix"
                ];
                fileSystems = {
                    "/".fsType = "tmpfs";
                };
                boot.loader.external = {
                  enable = true;
                  installHook = "${pkgs.coreutils}/bin/true";
                };
                nix.enable = true;
                nix.settings.experimental-features = [ "nix-command" "flakes" ];
                users.users.buildkite = {
                  isNormalUser = true;
                  extraGroups = [];
                  password = "";
                  uid = 2000;
                  shell = pkgs.bash;
                };
                users.groups.buildkite.gid = config.users.users.buildkite.uid;
                environment.systemPackages = with pkgs; [
                  buildkite-agent buildkite-cli gh bashInteractive git-repo git jdk21
                  ccache ninja
                  util-linux coreutils findutils procps cacert nix nix-bundle iana-etc
                ];
                system.stateVersion = "24.11";
              })
            ];
          };
          in nixosSystem.config.system.build.tarball;
          /*pkgs.dockerTools.buildLayeredImage {
            name = "xos-buildkite";
            tag = "15.2.0";

            /*enableFakechroot = true;
            fakeRootCommands = ''
              #!${pkgs.runtimeShell}
              ${pkgs.dockerTools.shadowSetup}
              groupadd -g 2000 buildkite
              useradd -m -s /bin/bash -u 2000 -g 2000 buildkite
              usermod -a -G nix-users buildkite
            '';
            contents = with pkgs; [
              buildkite-agent buildkite-cli gh bash git-repo git jdk21
              ccache ninja
              util-linux coreutils findutils procps
              nix-bundle nix iana-etc openssl
            ];
            config = { Cmd = [ "bash" "-ec" "nix-daemon & runuser -u buildkite -g buildkite -G nix-users -- env buildkite-agent start & wait -n; exit $?"]; };
            * /
            contents = [ nixosSystem.config.system.build.tarball ];
            config = { Cmd = [ "/init" ]; };
          };*/
        }
      );
    };
}