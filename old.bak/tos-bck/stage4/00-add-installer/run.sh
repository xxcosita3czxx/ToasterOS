#!/bin/bash -e

mkdir -p "${ROOTFS_DIR}/home/toaster/ToasterOS/setup/"
mkdir -p "${ROOTFS_DIR}/etc/systemd/system/"
mkdir -p "${ROOTFS_DIR}/usr/share/icons"

install -m 644 "files/setup.py" "${ROOTFS_DIR}/home/toaster/ToasterOS/setup/"
install -m 644 "files/setup-reqs.txt" "${ROOTFS_DIR}/home/toaster/ToasterOS/setup/"
install -m 644 "files/setup.service" "${ROOTFS_DIR}/etc/systemd/system/"
install -m 644 "files/logo-transparent.jpg" "${ROOTFS_DIR}/usr/share/icons/"
install -m 644 "files/logo.jpg" "${ROOTFS_DIR}/usr/share/icons/"

on_chroot << EOF
pip install -r /home/toaster/ToasterOS/setup/setup-reqs.txt
systemctl enable setup.service
EOF