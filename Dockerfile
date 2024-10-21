FROM nixos/nix

RUN nix-channel --update

ADD build.nix /tmp/build.nix
RUN nix-build -o /buildkite-agent /tmp/build.nix

ENTRYPOINT ["/buildkite-agent", "start"]
