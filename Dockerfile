FROM archlinux

RUN pacman -Syu --needed --noconfirm nix

RUN nix-channel --add https://nixos.org/channels/nixos-25.05 nixpkgs
RUN nix-channel --update
RUN echo "max-jobs = auto" >> /etc/nix/nix.conf
RUN echo "experimental-features = nix-command flakes" >> /etc/nix/nix.conf

RUN nix-env --file '<nixpkgs>' --install --attr buildkite-agent buildkite-cli gh bash git-repo git jdk21
RUN nix-env --file '<nixpkgs>' --install --attr ccache ninja
RUN nix-env --file '<nixpkgs>' --install --attr util-linux coreutils findutils procps

RUN groupadd -g 2000 buildkite
RUN useradd -m -s /bin/bash -u 2000 -g 2000 buildkite
RUN echo "trusted-users = buildkite" >> /etc/nix/nix.conf

ENTRYPOINT ["bash", "-ec", "nix-daemon & runuser -u buildkite -g buildkite -- env PATH=/nix/var/nix/profiles/default/bin:/usr/bin:/bin buildkite-agent start & wait -n; exit $?"]
