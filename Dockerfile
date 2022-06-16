from archlinux

run pacman -Syu --needed --noconfirm \
      base-devel bc ccache curl git gnupg \
      inetutils jdk11-openjdk libxslt ncurses \
      repo rsync python2 squashfs-tools unzip \
      zip zlib ffmpeg lzop ninja pngcrush openssl \
      gradle maven libxcrypt-compat xmlstarlet

run curl -L https://github.com/halogenOS/arch_ncurses5-compat-libs/releases/download/v6.3-abi5-1/ncurses5-compat-libs-6.3-1-x86_64.pkg.tar.zst > ncurses5-compat-libs.pkg.tar.zst
run pacman --noconfirm -U ncurses5-compat-libs.pkg.tar.zst

run useradd -M -s /bin/bash builder
run mkdir /tmp/pkgbuild && chown builder /tmp/pkgbuild
user builder
workdir /tmp/pkgbuild

run git clone https://aur.archlinux.org/buildkite-agent-bin.git
run cd buildkite-agent-bin && makepkg

user root
workdir /

run pacman --noconfirm -U /tmp/pkgbuild/buildkite-agent-bin/*.pkg.tar.*
run rm -rf /tmp/pkgbuild

entrypoint ["/usr/bin/buildkite-agent"]
