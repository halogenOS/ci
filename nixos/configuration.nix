{
  foundrixModules,
  lib,
  pkgs,
  config,
  ...
}:
{
  imports = [
    foundrixModules.profiles.server-baseline
    foundrixModules.config.shell.zsh.lite
  ];

  services.xos-buildkite = {
    tokenPath = "/var/credentials/buildkite-agent-token";
    organizationSlug = "halogenos";
    tags = {
      os = "nixos";
      for = "halogenos";
    };
    buildDir = "/var/lib/buildkite-agent/builds";
    ccache = {
      enable = true;
      dir = "/var/cache/ccache";
      maxSize = "80G";
    };
    credentialsFile = "/var/credentials/buildkite-credentials";
  };

  networking.hostName = "ci";

  system.stateVersion = "25.11";
}
