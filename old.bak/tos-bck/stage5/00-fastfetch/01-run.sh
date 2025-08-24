install -m 644 "files/fastfetch.conf" "${ROOTFS_DIR}/home/toaster/.config/fastfetch.conf"
install -m 644 "files/FastFetchImage" "${ROOTFS_DIR}/home/toaster/.config/FastFetchImage.txt"

wget -qO ${WORK_DIR}/fastfetch.tar.gz https://github.com/fastfetch-cli/fastfetch/releases/latest/download/fastfetch-linux-aarch64.tar.gz
sudo tar xf ${WORK_DIR}/fastfetch.tar.gz --strip-components=3 -C ${ROOTFS_DIR}/usr/local/bin fastfetch-linux-aarch64/usr/bin/fastfetch
