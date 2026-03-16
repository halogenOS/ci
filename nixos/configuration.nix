{
  foundrixModules,
  lib,
  pkgs,
  config,
  ...
}:
let
  userName = "user";
in
{
  imports = [
    foundrixModules.profiles.server-baseline
    foundrixModules.config.home-manager
    foundrixModules.config.shell.zsh.lite
    ./home.nix
  ];

  users.users.${userName} = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    uid = 1000;
    shell = pkgs.zsh;
    # Generate with: nix run nixpkgs#mkpasswd
    initialPassword = lib.warn "Set hashedPassword and remove initialPassword" "changeme";
    #hashedPassword = "$y$...";
    openssh.authorizedKeys.keys = [
      # Add your SSH public key here
      #"ssh-ed25519 AAAA..."
    ];
  };
  users.groups.${userName}.gid = config.users.users.${userName}.uid;

  home-manager.users.${userName}.home.stateVersion = "25.11";

  security.sudo.enable = true;

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
  };

  users.users.root.openssh.authorizedKeys.keys =
    config.users.users.${userName}.openssh.authorizedKeys.keys;

  services.xos-buildkite = {
    credentialsFile = "/var/credentials/buildkite-credentials";
    ccache.enable = true;
  };

  nix.settings.trusted-users = [
    "root"
    "@wheel"
  ];

  boot.uki.name = "xos-builder";

  system.stateVersion = "25.11";
}
