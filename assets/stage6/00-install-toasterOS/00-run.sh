#!/bin/bash

install -d "${ROOTFS_DIR}/usr/share/ToasterOS"
install -m 755 files/ToasterOS.deb "${ROOTFS_DIR}/usr/share/ToasterOS/ToasterOS.deb"
on_chroot << EOF
apt update
apt install libgtk-3-0 libgdk-pixbuf2.0-0 plymouth plymouth-themes xscreensaver xscreensaver-data-extra xscreensaver-gl-extra -y
apt install /usr/share/ToasterOS/ToasterOS.deb -y
EOF
rm "${ROOTFS_DIR}/usr/share/ToasterOS/ToasterOS.deb"
