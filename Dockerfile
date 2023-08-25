from archlinux as bk-builder

run pacman -Sy --needed --noconfirm git fakeroot base-devel

run useradd -M -s /bin/bash builder
run mkdir /tmp/pkgbuild && chown builder /tmp/pkgbuild
user builder
workdir /tmp/pkgbuild

run git clone https://aur.archlinux.org/buildkite-agent-bin.git
run cd buildkite-agent-bin && makepkg --noconfirm

from archlinux

run pacman -Syu --needed --noconfirm \
      base-devel bc ccache curl git gnupg \
      inetutils iputils net-tools libxslt ncurses \
      repo rsync squashfs-tools unzip \
      zip zlib ffmpeg lzop ninja pngcrush openssl \
      gradle maven libxcrypt-compat xmlstarlet \
      openssh gperf schedtool perl-switch ttf-dejavu \
      imagemagick jq pigz

# XOS-specific
run pacman -S --needed --noconfirm \
      github-cli jdk17-openjdk ninja

run yes | pacman -Scc --noconfirm

workdir /

copy --from=bk-builder /tmp/pkgbuild/buildkite-agent-bin/*.pkg.tar.* /tmp/

run pacman --noconfirm -U /tmp/*.pkg.tar.*
run curl -L https://github.com/halogenOS/arch_ncurses5-compat-libs/releases/download/v6.3-abi5-1/ncurses5-compat-libs-6.3-1-x86_64.pkg.tar.zst > /tmp/ncurses5-compat-libs.pkg.tar.zst
run pacman --noconfirm -U /tmp/ncurses5-compat-libs.pkg.tar.zst
run rm -rf /tmp/*.pkg.tar.*

run groupadd -g 2000 buildkite
run useradd -m -s /bin/bash -u 2000 -g 2000 buildkite
user buildkite

entrypoint ["/usr/bin/buildkite-agent", "start"]
