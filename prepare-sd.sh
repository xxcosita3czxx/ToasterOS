#!/usr/bin/env bash
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    exec sudo "$0" "$@"
fi

DEVICE=""
IMAGE=""
IMAGE_SIZE="8G"
COMPRESS_IMAGE=1
ROOT_IMAGE=""
BOOT_TAR=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --drive)
            DEVICE="$2"
            shift 2
            ;;
        --image)
            IMAGE="$2"
            shift 2
            ;;
        --root-image)
            ROOT_IMAGE="$2"
            shift 2
            ;;
        --boot-tar)
            BOOT_TAR="$2"
            shift 2
            ;;
        --no-compress)
            COMPRESS_IMAGE=0
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

if [[ -z "$DEVICE" && -z "$IMAGE" ]]; then
    echo "Usage:"
    echo "  $0 --drive /dev/sdX"
    echo "  $0 --image out/tosteros-rpi4.img --size 8G"
    echo "  $0 --image out/tosteros-rpi4.img --root-image out/tosteros-root.img.zst --boot-tar out/tosteros-boot.tar.zst"
    exit 1
fi

if [[ -n "$DEVICE" && -n "$IMAGE" ]]; then
    echo "Use either --drive or --image, not both."
    exit 1
fi

if [[ -n "$ROOT_IMAGE" && ! -f "$ROOT_IMAGE" ]]; then
    echo "Root image not found: $ROOT_IMAGE"
    exit 1
fi

if [[ -n "$BOOT_TAR" && ! -f "$BOOT_TAR" ]]; then
    echo "Boot tar not found: $BOOT_TAR"
    exit 1
fi

LOOP=""
IMAGE_MODE=0
MNT="/mnt/tosteros-prepare"
BOOT_MNT="/mnt/tosteros-boot"
IMAGE_SIZE="8G"

cleanup() {
    set +e
    umount -R "$BOOT_MNT" 2>/dev/null || true
    umount -R "$MNT" 2>/dev/null || true

    if [[ -n "${LOOP:-}" ]]; then
        losetup -d "$LOOP" 2>/dev/null || true
    fi
}
trap cleanup EXIT

if [[ -n "$IMAGE" ]]; then
    IMAGE_MODE=1

    mkdir -p "$(dirname "$IMAGE")"
    rm -f "$IMAGE" "$IMAGE.xz"

    echo "Creating flashable image: $IMAGE ($IMAGE_SIZE)"
    truncate -s "$IMAGE_SIZE" "$IMAGE"

    LOOP="$(losetup --find --show --partscan "$IMAGE")"
    DEVICE="$LOOP"
else
    if [[ ! -b "$DEVICE" ]]; then
        echo "Device does not exist: $DEVICE"
        exit 1
    fi

    echo "WARNING: this will erase $DEVICE"
    read -rp "Type YES to continue: " CONFIRM

    if [[ "$CONFIRM" != "YES" ]]; then
        echo "Aborted."
        exit 1
    fi
fi

if [[ "$DEVICE" =~ (nvme|mmcblk|loop) ]]; then
    PART_PREFIX="${DEVICE}p"
else
    PART_PREFIX="${DEVICE}"
fi

EFI_PART="${PART_PREFIX}1"
BTRFS_PART="${PART_PREFIX}2"

echo "[1/7] Unmounting old mounts..."
umount -R "$BOOT_MNT" 2>/dev/null || true
umount -R "$MNT" 2>/dev/null || true
umount "$EFI_PART" 2>/dev/null || true
umount "$BTRFS_PART" 2>/dev/null || true

echo "[2/7] Wiping disk..."
wipefs -af "$DEVICE"
sgdisk --zap-all "$DEVICE"

echo "[3/7] Creating partitions..."
parted -s "$DEVICE" mklabel gpt
parted -s "$DEVICE" mkpart ESP fat32 2MiB 512MiB
parted -s "$DEVICE" set 1 esp on
parted -s "$DEVICE" mkpart system btrfs 512MiB 100%

partprobe "$DEVICE"
udevadm settle

echo "[4/7] Formatting..."
mkfs.vfat -F32 -n BOOT "$EFI_PART"
mkfs.btrfs -f -L SYSTEM "$BTRFS_PART"

echo "[5/7] Creating Btrfs subvolumes..."
mkdir -p "$MNT"
mount "$BTRFS_PART" "$MNT"

btrfs subvolume create "$MNT/@root"
btrfs subvolume create "$MNT/@var"
btrfs subvolume create "$MNT/@home"
btrfs subvolume create "$MNT/@snapshots"

echo "[6/7] Applying optional images..."

if [[ -n "$ROOT_IMAGE" ]]; then
    echo "Applying root image: $ROOT_IMAGE"

    btrfs subvolume delete "$MNT/@root"

    zstd -dc "$ROOT_IMAGE" | btrfs receive "$MNT/@snapshots"

    RECEIVED="$(find "$MNT/@snapshots" -mindepth 1 -maxdepth 1 -type d | head -n1)"

    if [[ -z "$RECEIVED" ]]; then
        echo "No received root subvolume found."
        exit 1
    fi

    btrfs property set -f -ts "$RECEIVED" ro false
    mv "$RECEIVED" "$MNT/@root"
    btrfs property set -f -ts "$MNT/@root" ro true
fi

if [[ -n "$BOOT_TAR" ]]; then
    echo "Applying boot payload: $BOOT_TAR"

    mkdir -p "$BOOT_MNT"
    mount "$EFI_PART" "$BOOT_MNT"

    find "$BOOT_MNT" -mindepth 1 \
        ! -name usercfg.txt \
        ! -name usercmdline.txt \
        -exec rm -rf {} +

    tar -I zstd -xpf "$BOOT_TAR" -C "$BOOT_MNT"

    touch "$BOOT_MNT/usercfg.txt"
    touch "$BOOT_MNT/usercmdline.txt"

    sync
    umount "$BOOT_MNT"
fi

sync
umount "$MNT"

if [[ "$IMAGE_MODE" == "1" ]]; then
    echo "Shrinking image to used partition size..."

    losetup -d "$LOOP"
    LOOP=""

    LAST_END="$(parted -sm "$IMAGE" unit B print | awk -F: '/^[0-9]+:/ {gsub("B","",$3); end=$3} END {print end}')"

    TRUNCATE_SIZE=$((LAST_END + 1048576))

    TRUNCATE_SIZE=$(( (TRUNCATE_SIZE + 511) / 512 * 512 ))

    truncate -s "$TRUNCATE_SIZE" "$IMAGE"
fi

echo "[7/7] Done."
echo "Prepared TosterOS target:"
echo "  BOOT:   $EFI_PART"
echo "  SYSTEM: $BTRFS_PART"

if [[ "$IMAGE_MODE" == "1" ]]; then
    if [[ "$COMPRESS_IMAGE" == "1" ]]; then
        echo "Compressing image for Raspberry Pi Imager..."
        zstd -T0 -15 --rm "$IMAGE"
        chmod 666 "$IMAGE.xz"
        echo "Flashable image:"
        echo "  $IMAGE.xz"
    else
        chmod 666 "$IMAGE"
        echo "Flashable image:"
        echo "  $IMAGE"
    fi
fi
