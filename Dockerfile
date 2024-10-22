FROM nixos/nix

RUN nix-channel --update
RUN nix-env --file '<nixpkgs>' --install --attr buildkite-agent buildkite-cli gh bash git-repo git jdk21
RUN nix-env --file '<nixpkgs>' --install --attr ccache ninja

RUN nix-env --file '<nixpkgs>' --install --attr shadow
RUN cp -aL /etc/group /tmp/_group && cp -aL /etc/passwd /tmp/_passwd && cp -aL /etc/shadow /tmp/_shadow
RUN mv /tmp/_group /etc/group && mv /tmp/_passwd /etc/passwd && mv /tmp/_shadow /etc/shadow
RUN groupadd -g 2000 buildkite
RUN useradd -m -s $(nix --extra-experimental-features nix-command eval -f '<nixpkgs>' --raw bash)/bin/bash -u 2000 -g 2000 buildkite
USER buildkite

ENTRYPOINT ["bash", "-ec", "nix-daemon & buildkite-agent start & wait -n; exit $?"]
