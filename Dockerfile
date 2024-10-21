FROM nixos/nix

RUN nix-channel --update
RUN nix-env --file '<nixpkgs>' --install --attr buildkite-agent buildkite-cli gh bash git-repo git jdk21

ENTRYPOINT ["buildkite-agent", "start"]
