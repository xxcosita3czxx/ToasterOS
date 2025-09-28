build_rpi_blobs() {
	for i in raspberrypi-bootloader-common raspberrypi-bootloader; do
		apk fetch --root "$APKROOT" --quiet --stdout "$i" | tar -C "${DESTDIR}" -zx --strip=1 boot/ || return 1
	done
}

rpi_gen_cmdline() {
	echo "modules=loop,squashfs,sd-mod,usb-storage quiet ${kernel_cmdline}"
}

rpi_gen_config() {
	local arm_64bit=0
	case "$ARCH" in
		aarch64) arm_64bit=1;;
	esac
	cat <<-EOF
		# do not modify this file as it will be overwritten on upgrade.
		# create and/or modify usercfg.txt instead.
		# https://www.raspberrypi.com/documentation/computers/config_txt.html

		kernel=boot/vmlinuz-rpi
		initramfs boot/initramfs-rpi
		arm_64bit=$arm_64bit
        disable_overscan=1
		dtoverlay=vc4-kms-v3d
	EOF
}

build_rpi_config() {
	rpi_gen_cmdline > "${DESTDIR}"/cmdline.txt
	rpi_gen_config > "${DESTDIR}"/config.txt
}

section_rpi_config() {
	build_section rpi_config $( (rpi_gen_cmdline ; rpi_gen_config) | checksum )
	build_section rpi_blobs
}

profile_toaster() {
	profile_base
	title="ToasterOS for Raspberry Pi"
	desc="First generation Pis including Zero/W (armhf).
		Pi 2 to Pi 3+ generations (armv7).
		Pi 3 to Pi 5 generations (aarch64)."
	image_ext="tar.gz"
	arch="aarch64 armhf armv7"
	kernel_flavors="rpi"
	kernel_cmdline="console=tty1"
	initfs_features="base squashfs mmc usb kms dhcp https"
	hostname="toasteros-installer"
	grub_mod=
    apks="$apks \
	nano \
	python3 \
	py3-pip \
	sdl2 sdl2-dev \
	sdl2_ttf sdl2_ttf-dev \
	libdrm \
	libinput-dev \
	xf86-input-libinput \
	eudev \
	mesa-gbm \
	mesa-dri-gallium \
	mesa-egl \
	kbd \
	sed \
	agetty \
	networkmanager \
	networkmanager-cli"
    apkovl="aports/scripts/genapkovl-toaster.sh"
}

create_image_imggz() {
	sync "$DESTDIR"
	local image_size=$(du -L -k -s "$DESTDIR" | awk '{print $1 + 8192}' )
	local imgfile="${OUTDIR}/${output_filename%.gz}"
	dd if=/dev/zero of="$imgfile" bs=1M count=$(( image_size / 1024 ))
	mformat -i "$imgfile" -N 0 ::
	mcopy -s -i "$imgfile" "$DESTDIR"/* "$DESTDIR"/.alpine-release ::
	echo "Compressing $imgfile..."
	pigz -v -f -9 "$imgfile" || gzip -f -9 "$imgfile"
}

profile_toasterimg() {
	profile_toaster
	title="ToasterOS for Raspberry Pi Disk Image"
	image_name="alpine-rpi"
	image_ext="img.gz"
}
