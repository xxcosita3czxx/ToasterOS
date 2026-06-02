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
PRESET_NAME="$(basename "$PRESET" .sh)"
POSTCOPY_DIR="$(dirname "$PRESET")/${PRESET_NAME}.postcopy"

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
STEPS=12

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

echo "[1/$STEPS] Installing build tools..."

MISSING="$(pacman -T arch-install-scripts btrfs-progs zstd dosfstools rsync)"

if [[ -n "$MISSING" ]]; then
    pacman -Sy --noconfirm $MISSING
else
    echo "Build tools already installed."
fi

echo "[2/$STEPS] Preparing pacman config..."
mkdir -p "$WORK" "$OUT" "$MNT"

echo "$PACMAN_CONF" > "$PACMAN_CONF_FILE"

echo "[3/$STEPS] Preparing loopback Btrfs image..."
rm -f "$IMG"
truncate -s "$IMAGE_SIZE" "$IMG"
mkfs.btrfs -f -L "$ROOT_LABEL" "$IMG"

mount -o loop,noatime,nodiratime "$IMG" "$MNT"

cleanup() {
    set +e
    umount -R "$MNT" 2>/dev/null || true
}
trap cleanup EXIT

echo "[4/$STEPS] Creating @root..."
btrfs subvolume create "$MNT/@root"
ROOT="$MNT/@root"

echo "[5/$STEPS] Pacstrapping Arch Linux ARM..."
arch-chroot "$ROOT" /usr/bin/qemu-aarch64-static /bin/bash <<EOF
pacman-key --init
EOF
pacstrap -C "$PACMAN_CONF_FILE" "$ROOT" "${PACKAGES[@]}"
cp /usr/bin/qemu-aarch64-static "$ROOT/usr/bin/" || true

echo "[6/$STEPS] Writing base config..."
echo "$HOSTNAME" > "$ROOT/etc/hostname"
echo "$OS_RELEASE" > "$ROOT/etc/os-release"
echo "$FSTAB" > "$ROOT/etc/fstab"
cat > "$ROOT/etc/mkinitcpio.conf" <<EOF
MODULES=()
BINARIES=(btrfs)
FILES=()
HOOKS=($INITCPIO_HOOKS)
EOF

mkdir -p "$ROOT/boot" "$ROOT/var" "$ROOT/home" "$ROOT/.snapshots"

echo "[7/$STEPS] Writing Raspberry Pi boot config..."
cat > "$ROOT/boot/cmdline.txt" <<EOF
${CMDLINE}
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

echo "[8/$STEPS] Adding /etc overlay systemd unit..."
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

echo "[9/$STEPS] Copying post-install stuff..."
if [[ -d "$POSTCOPY_DIR" ]]; then
    echo "Applying postcopy overlay: $POSTCOPY_DIR"
    rsync -aAXH "$POSTCOPY_DIR"/ "$ROOT"/
fi

if [[ -n "${POSTINSTALL_SCRIPTS:-}" ]]; then
    echo "Running preset postinstall commands..."
    
    arch-chroot "$ROOT" /usr/bin/qemu-aarch64-static /bin/bash <<EOF
$POSTINSTALL_SCRIPTS
EOF
fi

echo "[10/$STEPS] Enabling preset services..."
mkdir -p "$ROOT/etc/systemd/system/multi-user.target.wants"

for service in "${ENABLED_SERVICES[@]}"; do
    if [[ -f "$ROOT/usr/lib/systemd/system/$service" ]]; then
        ln -sf "/usr/lib/systemd/system/$service" \
            "$ROOT/etc/systemd/system/multi-user.target.wants/$service"
    else
        echo "Warning: service not found: $service"
    fi
done

echo "[11/$STEPS] Cleaning rootfs..."
rm -rf "$ROOT/var/cache/pacman/pkg/"*
rm -rf "$ROOT/var/lib/pacman/sync/"*
rm -rf "$ROOT/tmp/"*

echo "[12/$STEPS] Exporting images..."
rm -f "$OUT/${IMAGE_NAME}-root.img.zst"
rm -f "$OUT/${IMAGE_NAME}-boot.tar.zst"

# Export boot partition contents first
tar -C "$ROOT/boot" -I "zstd -T0 -${COMPRESSION_LEVEL}" \
    -cpf "$OUT/${IMAGE_NAME}-boot.tar.zst" .

# Remove duplicated boot files from rootfs
rm -rf "$ROOT/boot"/*
mkdir -p "$ROOT/boot"

# Now snapshot/send root without boot files
btrfs subvolume snapshot -r "$ROOT" "$MNT/@root_ro"

btrfs send "$MNT/@root_ro" | \
    zstd -T0 -"${COMPRESSION_LEVEL}" -o "$OUT/${IMAGE_NAME}-root.img.zst"
chmod 666 "$OUT/${IMAGE_NAME}-boot.tar.zst" "$OUT/${IMAGE_NAME}-root.img.zst"

echo
echo "Done:"
echo "  $OUT/${IMAGE_NAME}-root.img.zst"
echo "  $OUT/${IMAGE_NAME}-boot.tar.zst"

