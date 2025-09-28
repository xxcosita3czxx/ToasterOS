#!/bin/sh -e

HOSTNAME="$1"
if [ -z "$HOSTNAME" ]; then
	echo "usage: $0 hostname"
	exit 1
fi

cleanup() {
	rm -rf "$tmp"
}

makefile() {
	OWNER="$1"
	PERMS="$2"
	FILENAME="$3"
	cat > "$FILENAME"
	chown "$OWNER" "$FILENAME"
	chmod "$PERMS" "$FILENAME"
}

rc_add() {
	mkdir -p "$tmp"/etc/runlevels/"$2"
	ln -sf /etc/init.d/"$1" "$tmp"/etc/runlevels/"$2"/"$1"
}

tmp="$(mktemp -d)"
trap cleanup EXIT

mkdir -p "$tmp"/etc
makefile root:root 0644 "$tmp"/etc/hostname <<EOF
$HOSTNAME
EOF

mkdir -p "$tmp"/etc/network
makefile root:root 0644 "$tmp"/etc/network/interfaces <<EOF
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
EOF

mkdir -p "$tmp"/etc/apk
makefile root:root 0644 "$tmp"/etc/apk/world <<EOF
alpine-base
nano
python3
py3-pip
sdl2
sdl2-dev
sdl2_ttf
libdrm
mesa-dri-gallium
mesa-egl
EOF

mkdir -p "$tmp"/etc/
makefile root:root 0777 "$tmp"/etc/answers.txt <<EOF
# Example answer file for setup-alpine script
# If you don't want to use a certain option, then comment it out

# Use US layout with US variant
KEYMAPOPTS="cz cz"

# Set hostname to alpine-test
HOSTNAMEOPTS="-n toasteros"

# Search domain of example.com, Google public nameserver
#DNSOPTS="-d example.com 8.8.8.8"
DNS_OPTS=none
# Set timezone to UTC
TIMEZONEOPTS="-z UTC"

USEROPTS=none

# set http/ftp proxy
#PROXYOPTS="http://webproxy:8080"
PROXYOPTS=none

# Add a random mirror
APKREPOSOPTS="-1"

# Install Openssh
SSHDOPTS="-c openssh"

# Use openntpd
NTPOPTS="-c busybox"

# Use /dev/sda as a data disk
DISKOPTS="-m sys /dev/sda"
EOF

mkdir -p "$tmp"/etc/init.d
makefile root:root 0744 "$tmp"/etc/init.d/install <<EOF
#!/sbin/openrc-run

# PROVIDE: install
# REQUIRE: local
# KEYWORD: default

start() {
	if [ "\$(cat /etc/hostname)" = "toasteros-installer" ]; then
		lbu add /etc/init.d
		lbu add /boot
		cp /etc/init.d/postinstall-cp /etc/init.d/postinstall
		rc-update add postinstall default
		cd /etc
		export SDL_VIDEODRIVER=kmsdrm
		/etc/installer
		mv /etc/postinstall /etc/postinstall.bak
		mv /etc/postinstall.bak /etc/postinstall
		setup-alpine -e -f /etc/answers.txt
		rm -rf /etc/answers.txt
		rm -rf /etc/init.d/install
		#reboot
	fi
}

EOF

mkdir -p "$tmp"/etc/init.d
makefile root:root 0744 "$tmp"/etc/init.d/postinstall-cp <<EOF
#!/sbin/openrc-run

# PROVIDE: postinstall
# REQUIRE: local
# KEYWORD: boot

name="postinstall"

start() {
    if [ "\$(cat /etc/hostname)" = "toasteros" ]; then
        echo "Running one-time setup..."
		apk update
		apk add \
			python3 py3-pip \
			sdl2 sdl2_image sdl2_ttf sdl2_mixer \
			sdl2-dev \
			mesa-dri-gallium \
			mesa-egl \
			libdrm \
			xf86-video-fbdev \
			xf86-input-evdev
		echo -e "disable_overscan=1\ndtoverlay=vc4-kms-v3d" >> /boot/config.txt
		git clone https://github.com/xxcosita3czxx/toasterOSapp /root/toasterOSapp
		cd /root/toasterOSapp
		python install.py
		rm -rf /etc/init.d/postinstall
        echo "postinstall done"
        
        # Reboot after setup is complete
        reboot
    fi
}
EOF

mkdir -p "$tmp"/boot/
makefile root:root 0644 "$tmp"/boot/config.txt <<EOF
# Boot configuration for ToasterOS
# https://www.raspberrypi.com/documentation/computers/config_txt.html

kernel=boot/vmlinuz-rpi
initramfs boot/initramfs-rpi
arm_64bit=$arm_64bit
disable_overscan=1
dtoverlay=vc4-kms-v3d
EOF

cp /home/build/dist/installer "$tmp"/etc/
cp /home/build/dist/postinstall "$tmp"/etc/

rc_add devfs sysinit
rc_add dmesg sysinit
rc_add mdev sysinit
rc_add hwdrivers sysinit
rc_add modloop sysinit

rc_add hwclock boot
rc_add modules boot
rc_add sysctl boot
rc_add hostname boot
rc_add bootmisc boot
rc_add syslog boot1

rc_add install default

rc_add mount-ro shutdown
rc_add killprocs shutdown
rc_add savecache shutdown

# Recreate the archive with the apkovl included
tar -c -C "$tmp" etc | gzip -9n > $HOSTNAME.apkovl.tar.gz
