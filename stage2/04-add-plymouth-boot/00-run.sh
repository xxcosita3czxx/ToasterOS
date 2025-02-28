mkdir -p ${ROOTFS_DIR}/usr/share/plymouth/themes/toaster/bootanimation

install -m 644 files/toaster.plymouth ${ROOTFS_DIR}/usr/share/plymouth/themes/toaster/toaster.plymouth
install -m 644 files/toaster.script ${ROOTFS_DIR}/usr/share/plymouth/themes/toaster/toaster.script
install -m 644 files/bootanimation/ ${ROOTFS_DIR}/usr/share/plymouth/themes/toaster/bootanimation/

on_chroot << EOF
sudo plymouth-set-default-theme -R toaster
update-initramfs -u
EOF
