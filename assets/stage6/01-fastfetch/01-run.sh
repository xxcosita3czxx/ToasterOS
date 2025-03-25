mkdir -p "${ROOTFS_DIR}/home/toaster/.config/fastfetch/"
mkdir -p "${ROOTFS_DIR}/home/toaster/.local/share/fastfetch/ascii/"


install -m 644 -D "files/config.jsonc" "${ROOTFS_DIR}/home/toaster/.config/fastfetch/"
install -m 644 -D "files/FastFetchImg.txt" "${ROOTFS_DIR}/home/toaster/.local/share/fastfetch/ascii/"

wget -qO ${WORK_DIR}/fastfetch.tar.gz https://github.com/fastfetch-cli/fastfetch/releases/latest/download/fastfetch-linux-aarch64.tar.gz
sudo tar xf ${WORK_DIR}/fastfetch.tar.gz --strip-components=3 -C ${ROOTFS_DIR}/usr/bin fastfetch-linux-aarch64/usr/bin/fastfetch
