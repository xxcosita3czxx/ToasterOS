FROM alpine:latest

RUN apk add alpine-sdk alpine-conf syslinux xorriso squashfs-tools grub grub-efi doas pigz
RUN apk add mtools dosfstools grub-efi

RUN adduser build -G abuild --disabled-password
RUN echo "permit persist :abuild" >> /etc/doas.d/doas.conf
RUN echo "permit nopass :abuild" >> /etc/doas.d/doas.conf
USER build
WORKDIR /home/build
RUN abuild-keygen -i -a -n
RUN git clone --depth=1 https://gitlab.alpinelinux.org/alpine/aports.git
COPY mkimg.toaster.sh /home/build/aports/scripts/mkimg.toaster.sh
COPY genapkovl-toaster.sh /home/build/aports/scripts/genapkovl-toaster.sh
RUN doas -n chmod +x ~/aports/scripts/mkimg.toaster.sh
RUN doas -n chmod +x ~/aports/scripts/genapkovl-toaster.sh
RUN doas -n apk update
RUN mkdir -pv ~/tmp
RUN mkdir -p ~/iso

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]
