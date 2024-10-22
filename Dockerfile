FROM archlinux

RUN pacman -Syu --needed --noconfirm nix

RUN nix-channel --add https://nixos.org/channels/nixos-24.05 nixpkgs
RUN nix-channel --update
RUN echo "max-jobs = auto" >> /etc/nix/nix.conf

RUN nix-env --file '<nixpkgs>' --install --attr buildkite-agent buildkite-cli gh bash git-repo git jdk21
RUN nix-env --file '<nixpkgs>' --install --attr ccache ninja
RUN nix-env --file '<nixpkgs>' --install --attr util-linux coreutils findutils

RUN groupadd -g 2000 buildkite
RUN useradd -m -s /bin/bash -u 2000 -g 2000 buildkite
RUN usermod -a -G nix-users buildkite

ENTRYPOINT ["bash", "-ec", "nix-daemon & runuser -u buildkite -g buildkite -- env PATH=/nix/var/nix/profiles/default/bin buildkite-agent start & wait -n; exit $?"]
