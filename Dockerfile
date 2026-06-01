FROM archlinux:latest

WORKDIR /builder

RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm \
      arch-install-scripts \
      archlinux-keyring \
      btrfs-progs \
      zstd \
      dosfstools \
      rsync \
      util-linux \
      qemu-user-static \
      qemu-user-static-binfmt \
      sudo && \
    pacman -Scc --noconfirm

COPY build.sh /builder/build.sh
COPY presets /builder/presets

RUN chmod +x /builder/build.sh

ENTRYPOINT ["/builder/build.sh"]
