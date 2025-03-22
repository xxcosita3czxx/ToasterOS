#!/bin/bash

install -m 755 files/toasterOS.deb "${ROOTFS_DIR}/tmp/toasterOS.deb"
on_chroot << EOF
dpkg -i /tmp/toasterOS.deb
EOF
rm "${ROOTFS_DIR}/tmp/toasterOS.deb"
