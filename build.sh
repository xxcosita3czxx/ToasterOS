#!/usr/bin/env bash
set -euo pipefail

PRESET=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --preset)
            PRESET="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

if [[ -z "$PRESET" ]]; then
    echo "Usage: $0 --preset path/to/preset.conf"
    exit 1
fi

if [[ ! -f "$PRESET" ]]; then
    echo "Preset not found: $PRESET"
    exit 1
fi

source "$PRESET"

IMAGE_SIZE="${IMAGE_SIZE:-6G}"
IMAGE_NAME="${IMAGE_NAME:-atomic-alarm}"
HOSTNAME="${HOSTNAME:-atomic-alarm}"
COMPRESSION_LEVEL="${COMPRESSION_LEVEL:-19}"
ROOT_LABEL="${ROOT_LABEL:-SYSTEM}"
BOOT_LABEL="${BOOT_LABEL:-BOOT}"

WORK="${WORK:-/builder/work}"
OUT="${OUT:-/builder/out}"
IMG="$WORK/build-btrfs.img"
MNT="${MNT:-/mnt/atomic-build}"
PACMAN_CONF_FILE="$WORK/pacman-aarch64.conf"

if [[ ${#PACKAGES[@]} -eq 0 ]]; then
    PACKAGES=(
        base
        linux-rpi
        raspberrypi-bootloader
        archlinuxarm-keyring
        btrfs-progs
        zstd
        sudo
        nano
        networkmanager
    )
fi

if [[ ${#ENABLED_SERVICES[@]} -eq 0 ]]; then
    ENABLED_SERVICES=(
        NetworkManager.service
        systemd-resolved.service
    )
fi

echo "[1/11] Installing build tools..."
pacman -Syyu --noconfirm
pacman -S --noconfirm arch-install-scripts btrfs-progs zstd dosfstools rsync

echo "[2/11] Preparing pacman config..."
mkdir -p "$WORK" "$OUT" "$MNT"

echo "$PACMAN_CONF" > "$PACMAN_CONF_FILE"

echo "[3/11] Preparing loopback Btrfs image..."
rm -f "$IMG"
truncate -s "$IMAGE_SIZE" "$IMG"
mkfs.btrfs -f -L "$ROOT_LABEL" "$IMG"

mount -o loop "$IMG" "$MNT"

cleanup() {
    set +e
    umount -R "$MNT" 2>/dev/null || true
}
trap cleanup EXIT

echo "[4/11] Creating @root..."
btrfs subvolume create "$MNT/@root"
ROOT="$MNT/@root"

echo "[5/11] Pacstrapping Arch Linux ARM..."
pacstrap -M -K -C "$PACMAN_CONF_FILE" "$ROOT" "${PACKAGES[@]}"

echo "[6/11] Writing base config..."
echo "$HOSTNAME" > "$ROOT/etc/hostname"

echo "$FSTAB" > "$ROOT/etc/fstab"


mkdir -p "$ROOT/boot" "$ROOT/var" "$ROOT/home" "$ROOT/.snapshots"

echo "[7/11] Writing Raspberry Pi boot config..."
cat > "$ROOT/boot/cmdline.txt" <<EOF
root=LABEL=$ROOT_LABEL rootfstype=btrfs rootflags=subvol=@root,ro rootwait console=serial0,115200 console=tty1
EOF

if [[ -f "$ROOT/boot/config.txt" ]]; then
    grep -q '^include usercfg.txt' "$ROOT/boot/config.txt" || {
        echo "" >> "$ROOT/boot/config.txt"
        echo "include usercfg.txt" >> "$ROOT/boot/config.txt"
    }
else
    cat > "$ROOT/boot/config.txt" <<'EOF'
arm_64bit=1
enable_uart=1
include usercfg.txt
EOF
fi

touch "$ROOT/boot/usercfg.txt"

echo "[8/11] Adding /etc overlay systemd unit..."
mkdir -p "$ROOT/var/overlays/etc/upper"
mkdir -p "$ROOT/var/overlays/etc/work"
mkdir -p "$ROOT/etc/systemd/system/sysinit.target.wants"

cat > "$ROOT/etc/systemd/system/etc-overlay.service" <<'EOF'
[Unit]
Description=Overlay persistent /etc
DefaultDependencies=no
After=local-fs.target
Before=sysinit.target
ConditionPathIsDirectory=/var/overlays/etc/upper

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/bin/mount -t overlay overlay -o lowerdir=/etc,upperdir=/var/overlays/etc/upper,workdir=/var/overlays/etc/work /etc
ExecStop=/usr/bin/umount /etc

[Install]
WantedBy=sysinit.target
EOF

ln -sf /etc/systemd/system/etc-overlay.service \
    "$ROOT/etc/systemd/system/sysinit.target.wants/etc-overlay.service"

echo "[9/11] Enabling preset services..."
mkdir -p "$ROOT/etc/systemd/system/multi-user.target.wants"

for service in "${ENABLED_SERVICES[@]}"; do
    if [[ -f "$ROOT/usr/lib/systemd/system/$service" ]]; then
        ln -sf "/usr/lib/systemd/system/$service" \
            "$ROOT/etc/systemd/system/multi-user.target.wants/$service"
    else
        echo "Warning: service not found: $service"
    fi
done

echo "[10/11] Cleaning rootfs..."
rm -rf "$ROOT/var/cache/pacman/pkg/"*
rm -rf "$ROOT/var/lib/pacman/sync/"*
rm -rf "$ROOT/tmp/"*

echo "[11/11] Exporting images..."
rm -f "$OUT/${IMAGE_NAME}-root.img.zst"
rm -f "$OUT/${IMAGE_NAME}-boot.tar.zst"

tar -C "$ROOT/boot" -I "zstd -T0 -${COMPRESSION_LEVEL}" \
    -cpf "$OUT/${IMAGE_NAME}-boot.tar.zst" .

btrfs subvolume snapshot -r "$ROOT" "$MNT/@root_ro"

btrfs send "$MNT/@root_ro" | \
    zstd -T0 -"${COMPRESSION_LEVEL}" -o "$OUT/${IMAGE_NAME}-root.img.zst"

chmod 666 "$OUT/${IMAGE_NAME}-boot.tar.zst" "$OUT/${IMAGE_NAME}-root.img.zst"

echo
echo "Done:"
echo "  $OUT/${IMAGE_NAME}-root.img.zst"
echo "  $OUT/${IMAGE_NAME}-boot.tar.zst"

