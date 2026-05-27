FROM archlinux:latest

WORKDIR /builder

RUN pacman -Sy --noconfirm \
      arch-install-scripts \
      btrfs-progs \
      zstd \
      dosfstools \
      util-linux && \
    pacman -Scc --noconfirm

COPY build.sh /builder/build.sh
COPY presets /builder/presets

RUN chmod +x /builder/build.sh

ENTRYPOINT ["/builder/build.sh"]
