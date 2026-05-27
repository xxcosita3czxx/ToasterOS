IMAGE_NAME="toasteros-beta"
IMAGE_SIZE="6G"
HOSTNAME="toasteros"
COMPRESSION_LEVEL="19"

ROOT_LABEL="SYSTEM"
BOOT_LABEL="BOOT"

FSTAB=$(cat <<EOF
LABEL=$ROOT_LABEL / btrfs ro,subvol=@root,compress=zstd,noatime 0 0
LABEL=$BOOT_LABEL /boot vfat defaults 0 2
LABEL=$ROOT_LABEL /var btrfs rw,subvol=@var,compress=zstd,noatime 0 0
LABEL=$ROOT_LABEL /home btrfs rw,subvol=@home,compress=zstd,noatime 0 0
LABEL=$ROOT_LABEL /.snapshots btrfs rw,subvol=@snapshots,compress=zstd,noatime 0 0
EOF
)

PACMAN_CONF=$(cat <<EOF
[options]
Architecture = aarch64
SigLevel = Never
LocalFileSigLevel = Optional
ParallelDownloads = 5

[core]
Server = http://mirror.archlinuxarm.org/$arch/$repo

[extra]
Server = http://mirror.archlinuxarm.org/$arch/$repo

[alarm]
Server = http://mirror.archlinuxarm.org/$arch/$repo

[aur]
Server = http://mirror.archlinuxarm.org/$arch/$repo
EOF
)

PACKAGES=(
    base
    archlinuxarm-keyring
    linux-rpi
    raspberrypi-bootloader
    btrfs-progs
    zstd
    sudo
    nano
    networkmanager
)

ENABLED_SERVICES=(
    NetworkManager.service
    systemd-resolved.service
)
