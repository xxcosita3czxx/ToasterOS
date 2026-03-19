FROM alpine:latest 

RUN apk add alpine-sdk alpine-conf xorriso squashfs-tools grub grub-efi doas pigz
RUN apk add mtools dosfstools grub-efi
RUN apk add python3 py3-pip py3-setuptools py3-wheel
RUN apk add sdl2 sdl2-dev sdl2_ttf sdl2_ttf-dev mesa-dri-gallium mesa-egl

RUN adduser build -G abuild --disabled-password
RUN echo "permit persist :abuild" >> /etc/doas.d/doas.conf
RUN echo "permit nopass :abuild" >> /etc/doas.d/doas.conf
USER build
WORKDIR /home/build
RUN abuild-keygen -i -a -n
RUN git clone --depth=1 https://gitlab.alpinelinux.org/alpine/aports.git
RUN mkdir -p ~/build
COPY gui/requirements.txt /home/build/build/
COPY gui/m6x11pluscs.ttf /home/build/build/
COPY gui/installer.py /home/build/build/
COPY gui/postinstall.py /home/build/build/
COPY gui/Anims /home/build/build/Anims
COPY gui/animations.py /home/build/build/
RUN python -m pip install pyinstaller --break
RUN python -m pip install -r /home/build/build/requirements.txt --break
RUN python -m PyInstaller --onefile /home/build/build/installer.py --add-data "/home/build/build/m6x11pluscs.ttf:." --add-data "/home/build/build/Anims:Anims" --add-data "/home/build/build/animations.py:animations.py"
RUN python -m PyInstaller --onefile /home/build/build/postinstall.py --add-data "/home/build/build/m6x11pluscs.ttf:."
COPY mkimg.toaster.sh /home/build/aports/scripts/mkimg.toaster.sh
COPY genapkovl-toaster.sh /home/build/aports/scripts/genapkovl-toaster.sh
RUN doas -n chmod +x ~/aports/scripts/mkimg.toaster.sh
RUN doas -n chmod +x ~/aports/scripts/genapkovl-toaster.sh
RUN doas -n apk update
RUN mkdir -pv ~/tmp
RUN mkdir -p ~/iso

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]
