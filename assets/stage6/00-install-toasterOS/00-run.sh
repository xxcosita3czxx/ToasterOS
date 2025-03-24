#!/bin/bash

install -m 755 files/ToasterOS.deb "${ROOTFS_DIR}/tmp/toasterOS.deb"
on_chroot << EOF
dpkg -i /tmp/ToasterOS.deb
EOF
rm "${ROOTFS_DIR}/tmp/ToasterOS.deb"
