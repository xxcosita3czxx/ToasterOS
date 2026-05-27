#!/usr/bin/env bash
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    exec sudo "$0" "$@"
fi

DEVICE=""
ROOTFS_TAR=""
HOSTNAME="atomic-arch"
USERNAME="user"
PASSWORD="password"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --drive)
            DEVICE="$2"
            shift 2
            ;;
        --rootfs)
            ROOTFS_TAR="$2"
            shift 2
            ;;
        --hostname)
            HOSTNAME="$2"
            shift 2
            ;;
        --username)
            USERNAME="$2"
            shift 2
            ;;
        --password)
            PASSWORD="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

if [[ -z "$DEVICE" || -z "$ROOTFS_TAR" ]]; then
    echo "Usage:"
    echo "  $0 --drive /dev/sdX --rootfs ArchLinuxARM-rootfs.tar.gz"
    exit 1
fi

if [[ ! -b "$DEVICE" ]]; then
    echo "Device does not exist: $DEVICE"
    exit 1
fi

if [[ ! -f "$ROOTFS_TAR" ]]; then
    echo "Rootfs tarball does not exist: $ROOTFS_TAR"
    exit 1
fi

echo "WARNING: this will erase $DEVICE"
read -rp "Type YES to continue: " CONFIRM

if [[ "$CONFIRM" != "YES" ]]; then
    echo "Aborted."
    exit 1
fi

if [[ "$DEVICE" =~ (nvme|mmcblk|loop) ]]; then
    PART_PREFIX="${DEVICE}p"
else
    PART_PREFIX="${DEVICE}"
fi

EFI_PART="${PART_PREFIX}1"
ROOT_PART="${PART_PREFIX}2"
VAR_PART="${PART_PREFIX}3"
HOME_PART="${PART_PREFIX}4"

MNT="/mnt/atomic-arch"

echo "[1/8] Unmounting old mounts..."
umount -R "$MNT" 2>/dev/null || true
for p in "${EFI_PART}" "${ROOT_PART}" "${VAR_PART}" "${HOME_PART}"; do
    umount "$p" 2>/dev/null || true
done

echo "[2/8] Wiping disk..."
wipefs -af "$DEVICE"
sgdisk --zap-all "$DEVICE"

echo "[3/8] Creating partitions..."
parted -s "$DEVICE" mklabel gpt
parted -s "$DEVICE" mkpart ESP fat32 2MiB 512MiB
parted -s "$DEVICE" set 1 esp on
parted -s "$DEVICE" mkpart root btrfs 512MiB 8GiB
parted -s "$DEVICE" mkpart var ext4 8GiB 12GiB
parted -s "$DEVICE" mkpart home ext4 12GiB 100%

partprobe "$DEVICE"
udevadm settle

echo "[4/8] Formatting..."
mkfs.vfat -F32 -n BOOT "$EFI_PART"
mkfs.btrfs -f -L atomic_root "$ROOT_PART"
mkfs.ext4 -F -L atomic_var "$VAR_PART"
mkfs.ext4 -F -L atomic_home "$HOME_PART"

echo "[5/8] Creating Btrfs subvolume..."
mkdir -p "$MNT"
mount "$ROOT_PART" "$MNT"
btrfs subvolume create "$MNT/@root"
umount "$MNT"

echo "[6/8] Mounting target..."
mount -o subvol=@root,compress=zstd,noatime "$ROOT_PART" "$MNT"
mkdir -p "$MNT/boot" "$MNT/var" "$MNT/home"
mount "$EFI_PART" "$MNT/boot"
mount "$VAR_PART" "$MNT/var"
mount "$HOME_PART" "$MNT/home"

echo "[7/8] Extracting rootfs..."
bsdtar -xpf "$ROOTFS_TAR" -C "$MNT"

echo "[8/8] Basic config..."
echo "$HOSTNAME" > "$MNT/etc/hostname"

ROOT_UUID="$(blkid -s UUID -o value "$ROOT_PART")"
EFI_UUID="$(blkid -s UUID -o value "$EFI_PART")"
VAR_UUID="$(blkid -s UUID -o value "$VAR_PART")"
HOME_UUID="$(blkid -s UUID -o value "$HOME_PART")"

cat > "$MNT/etc/fstab" <<EOF
UUID=$ROOT_UUID / btrfs ro,subvol=@root,compress=zstd,noatime 0 0
UUID=$EFI_UUID /boot vfat umask=0077 0 2
UUID=$VAR_UUID /var ext4 defaults,noatime 0 2
UUID=$HOME_UUID /home ext4 defaults,noatime 0 2
EOF

arch-chroot "$MNT" /bin/bash <<EOF
set -e

echo "root:$PASSWORD" | chpasswd

if ! id "$USERNAME" >/dev/null 2>&1; then
    useradd -m -G wheel "$USERNAME"
fi

echo "$USERNAME:$PASSWORD" | chpasswd

sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

systemctl enable systemd-networkd.service
systemctl enable systemd-resolved.service

ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
EOF

echo "Locking root subvolume readonly..."
btrfs property set -ts "$MNT" ro true || true

echo "Unmounting..."
sync
umount -R "$MNT"

echo "Done."
echo "SD card prepared: $DEVICE"
