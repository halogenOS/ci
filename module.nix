{ config, lib, pkgs, ... }:

let
  cfg = config.services.xos-buildkite;

  hookCheckout = ''
    set -euo pipefail

    export GIT_TERMINAL_PROMPT=0
    export BUILDKITE_REFSPEC="''${BUILDKITE_REFSPEC:=main}"

    git config --global --add safe.directory "$(pwd)"

    if [[ -d ".git" ]]; then
      git remote set-url origin "$BUILDKITE_REPO"
    else
      git clone -v "$BUILDKITE_REPO" .
    fi

    git config pull.ff only
    git fetch -v origin
    ( git checkout "''${BUILDKITE_REFSPEC}" || git checkout "''${BUILDKITE_COMMIT}" ) || :
    git pull
  '';

  hookEnvironment = ''
    # shellcheck disable=SC1091
    set -euo pipefail

    if [[ "$BUILDKITE_ORGANIZATION_SLUG" == "${cfg.organizationSlug}" ]]; then
      ${lib.optionalString (cfg.credentialsFile != null) ''
        # shellcheck disable=SC1091
        source ${cfg.credentialsFile}
      ''}

      ${lib.optionalString (cfg.signingKeysDir != null) ''
        export KEYS_DIR=${cfg.signingKeysDir}
      ''}

      ${lib.optionalString cfg.ccache.enable ''
        export USE_CCACHE=1
        export CCACHE_DIR=${toString cfg.ccache.dir}
        export CCACHE_EXEC=${pkgs.ccache}/bin/ccache
        ${pkgs.ccache}/bin/ccache -M ${cfg.ccache.maxSize}
      ''}
    fi
  '';

in {
  options.services.xos-buildkite = {
    tokenPath = lib.mkOption {
      type = lib.types.path;
      default = "/var/credentials/buildkite-agent-token";
      description = "Path to a file containing the Buildkite agent token.";
    };

    organizationSlug = lib.mkOption {
      type = lib.types.str;
      default = "halogenos";
      description = "Buildkite organization slug for conditional hook logic.";
    };

    tags = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {
        os = "nixos";
        for = "halogenos";
      };
      description = "Agent tags as an attribute set.";
    };

    buildDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/buildkite-agent/builds";
      description = "Directory where builds run.";
    };

    manageBuildDir = lib.mkOption {
      type = lib.types.bool;
      default = cfg.buildDir == "/var/lib/buildkite-agent/builds";
      defaultText = lib.literalExpression "true when buildDir is the default";
      description = "Whether to create and manage the build directory via tmpfiles. Disable this when buildDir points to a user-managed mount or existing directory.";
    };

    spawn = lib.mkOption {
      type = lib.types.int;
      default = 1;
      description = "Number of parallel agents to spawn.";
    };

    priority = lib.mkOption {
      type = lib.types.int;
      default = 1;
      description = "Agent priority (higher = assigned work first).";
    };

    noCommandEval = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Disallow arbitrary console commands.";
    };

    credentialsFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = "/var/credentials/buildkite-credentials";
      description = "Path to a shell file with credential exports, sourced in the environment hook.";
    };

    signingKeysDir = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = "/var/credentials/xos-signing-keys";
      description = "Path to directory containing XOS AOSP signing keys.";
    };

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
      description = "Additional packages available to the buildkite agent.";
    };

    ccache = {
      enable = lib.mkEnableOption "ccache for builds";

      dir = lib.mkOption {
        type = lib.types.path;
        default = "/var/cache/ccache";
        description = "ccache directory.";
      };

      maxSize = lib.mkOption {
        type = lib.types.str;
        default = "80G";
        description = "Maximum ccache size.";
      };
    };
  };

  config = {
    nix.settings = {
      experimental-features = [ "nix-command" "flakes" ];
    };

    services.buildkite-agents.xos = {
      inherit (cfg) tokenPath;

      name = "%hostname-%spawn";
      tags = cfg.tags;
      privateSshKeyPath = null;

      runtimePackages = with pkgs; [
        bashInteractive git git-repo gh jdk21
        ccache ninja
        util-linux coreutils findutils procps
        nix cacert
      ] ++ cfg.extraPackages;

      hooks = {
        checkout = hookCheckout;
        environment = hookEnvironment;
      };

      extraConfig = ''
        build-path="${cfg.buildDir}"
        spawn=${toString cfg.spawn}
        priority=${toString cfg.priority}
        no-command-eval=${lib.boolToString cfg.noCommandEval}
        redacted-vars='*_PASSWORD','*_SECRET','*_TOKEN','*_ACCESS_KEY','*_SECRET_KEY','*_BOT_URL','*_API_KEY'
      '';
    };

    systemd.services.xos-buildkite-dirs = {
      description = "Create xos-buildkite runtime directories";
      wantedBy = [ "buildkite-agent-xos.service" ];
      before = [ "buildkite-agent-xos.service" ];
      after = [ "local-fs.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = let
          rules = lib.optional cfg.manageBuildDir
            "d ${cfg.buildDir} 0755 buildkite-agent-xos buildkite-agent-xos -"
          ++ lib.optional cfg.ccache.enable
            "d ${cfg.ccache.dir} 0755 buildkite-agent-xos buildkite-agent-xos -"
          ++ lib.optional (cfg.signingKeysDir != null)
            "d ${cfg.signingKeysDir} 0755 buildkite-agent-xos buildkite-agent-xos -";
          confFile = pkgs.writeText "xos-buildkite-tmpfiles.conf"
            (lib.concatStringsSep "\n" rules);
        in "${pkgs.systemd}/bin/systemd-tmpfiles --create ${confFile}";
      };
    };
  };
}
