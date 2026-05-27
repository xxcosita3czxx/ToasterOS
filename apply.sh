#!/usr/bin/env bash
set -euo pipefail

IMG="${1:-out/atomic-alarm-root.img.zst}"
MNT="/mnt/atomic-arch"

if [[ ! -f "$IMG" ]]; then
    echo "Image not found: $IMG"
    exit 1
fi

sudo mkdir -p "$MNT"
sudo mount LABEL=SYSTEM "$MNT"

cleanup() {
    sudo umount "$MNT" 2>/dev/null || true
}
trap cleanup EXIT

echo "[1/4] Removing old staged root..."
sudo btrfs subvolume delete "$MNT/@backups/old-root" 2>/dev/null || true
sudo btrfs subvolume delete "$MNT/@backups/new-root" 2>/dev/null || true

echo "[2/4] Receiving new root..."
zstd -dc "$IMG" | sudo btrfs receive "$MNT/@backups"

echo "[3/4] Moving received root..."
sudo mv "$MNT/@backups/@root_ro" "$MNT/@backups/new-root"

echo "[4/4] Replacing active @root..."
sudo btrfs subvolume snapshot -r "$MNT/@root" "$MNT/@backups/old-root" 2>/dev/null || true
sudo btrfs subvolume delete "$MNT/@root"
sudo btrfs subvolume snapshot "$MNT/@backups/new-root" "$MNT/@root"

sync

echo "Applied new @root."
