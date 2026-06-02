#!/usr/bin/env bash
set -euo pipefail

ROOT_IMG=""
BOOT_IMG=""

MNT="/mnt/atomic-arch"
BOOT_MNT="/mnt/atomic-boot"

ROOT_LABEL="SYSTEM"
BOOT_LABEL="BOOT"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --root)
            ROOT_IMG="$2"
            shift 2
            ;;
        --boot)
            BOOT_IMG="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--root root.img.zst] [--boot boot.tar.zst]"
            exit 1
            ;;
    esac
done

if [[ -z "$ROOT_IMG" && -z "$BOOT_IMG" ]]; then
    echo "Usage: $0 [--root root.img.zst] [--boot boot.tar.zst]"
    exit 1
fi

if [[ -n "$ROOT_IMG" && ! -f "$ROOT_IMG" ]]; then
    echo "Root image not found: $ROOT_IMG"
    exit 1
fi

if [[ -n "$BOOT_IMG" && ! -f "$BOOT_IMG" ]]; then
    echo "Boot image not found: $BOOT_IMG"
    exit 1
fi

cleanup() {
    sudo umount "$BOOT_MNT" 2>/dev/null || true
    sudo umount "$MNT" 2>/dev/null || true
}
trap cleanup EXIT

apply_root() {
    sudo mkdir -p "$MNT"
    sudo mount "LABEL=$ROOT_LABEL" "$MNT"

    echo "[root 1/4] Removing old staged root..."
    sudo btrfs subvolume delete "$MNT/@snapshots/old-root" 2>/dev/null || true
    sudo btrfs subvolume delete "$MNT/@snapshots/new-root" 2>/dev/null || true

    echo "[root 2/4] Receiving new root..."
    sudo bash -c "zstd -dc '$ROOT_IMG' | btrfs receive '$MNT/@snapshots'"

    echo "[root 3/4] Moving received root..."
    sudo mv "$MNT/@snapshots/@root_ro" "$MNT/@snapshots/new-root"

    echo "[root 4/4] Replacing active @root..."
    sudo btrfs subvolume snapshot -r "$MNT/@root" "$MNT/@snapshots/old-root" 2>/dev/null || true
    sudo btrfs subvolume delete "$MNT/@root"
    sudo btrfs subvolume snapshot "$MNT/@snapshots/new-root" "$MNT/@root"

    sudo umount "$MNT"
}

apply_boot() {
    sudo mkdir -p "$BOOT_MNT"
    sudo mount -o uid=0,gid=0,umask=022 "LABEL=$BOOT_LABEL" "$BOOT_MNT"

    echo "[boot 1/2] Cleaning BOOT partition..."
    sudo rm -rf "$BOOT_MNT"/*

    echo "[boot 2/2] Extracting boot files..."
    sudo zstd -dc "$BOOT_IMG" | sudo tar -C "$BOOT_MNT" --no-same-owner --no-same-permissions -xf -

    sudo umount "$BOOT_MNT"
}

if [[ -n "$BOOT_IMG" ]]; then
    apply_boot
fi

if [[ -n "$ROOT_IMG" ]]; then
    apply_root
fi


sync

echo "Applied selected images."