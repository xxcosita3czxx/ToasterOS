VERSION="beta"
PRETTY_VERSION="Beta"
IMAGE_NAME="toasteros-$VERSION"
IMAGE_SIZE="6G"
HOSTNAME="toasteros"
COMPRESSION_LEVEL="0"
ROOT_LABEL="SYSTEM"
BOOT_LABEL="BOOT"
CMDLINE="root=LABEL=$ROOT_LABEL rootfstype=btrfs rootflags=subvol=@root,ro dtoverlay=vc4-kms-v3d quiet splash rootwait console=tty1"
INITCPIO_HOOKS="base systemd plymouth modconf kms keyboard block filesystems"
USERNAME="toaster"
PASSWORD="toaster"
ROOT_PASSWORD="$PASSWORD"
OS_RELEASE=$(cat <<EOF
NAME="ToasterOS"
PRETTY_NAME="ToasterOS $PRETTY_VERSION (Arch Linux ARM)"
ID=archarm
ID_LIKE=arch
BUILD_ID="$VERSION"
ANSI_COLOR="38;2;23;147;209"
HOME_URL="https://archlinuxarm.org/"
DOCUMENTATION_URL="https://archlinuxarm.org/wiki"
SUPPORT_URL="https://archlinuxarm.org/forum"
BUG_REPORT_URL="https://github.com/archlinuxarm/PKGBUILDs/issues"
LOGO=archlinux-logo
EOF
)

FSTAB=$(cat <<EOF
LABEL=$ROOT_LABEL /           btrfs ro,subvol=@root,compress=zstd,noatime      0 0
LABEL=$BOOT_LABEL /boot       vfat  defaults                                   0 2
LABEL=$ROOT_LABEL /var        btrfs rw,subvol=@var,compress=zstd,noatime       0 0
LABEL=$ROOT_LABEL /home       btrfs rw,subvol=@home,compress=zstd,noatime      0 0
LABEL=$ROOT_LABEL /.snapshots btrfs rw,subvol=@snapshots,compress=zstd,noatime 0 0
EOF
)

PACMAN_CONF=$(cat <<EOF
[options]
Architecture = aarch64
SigLevel = Never
LocalFileSigLevel = Optional
ParallelDownloads = 5
Color
ILoveCandy

[core]
Server = http://mirror.archlinuxarm.org/\$arch/\$repo

[extra]
Server = http://mirror.archlinuxarm.org/\$arch/\$repo

[alarm]
Server = http://mirror.archlinuxarm.org/\$arch/\$repo

[aur]
Server = http://mirror.archlinuxarm.org/\$arch/\$repo
EOF
)

BASE_PACKAGES=(
    base
    base-devel
    raspberrypi-bootloader
    linux-rpi
    btrfs-progs
    archlinuxarm-keyring
    plymouth
    networkmanager
)

DRIVER_PACKAGES=(
    mesa
    xf86-video-amdgpu
    xf86-video-nouveau
)

UI_PACKAGES=(
    xorg-server
    sddm
    sdl3
   	sdl3_image
)

EXTRA_PACKAGES=(
    sudo
    fastfetch
    nano
    zstd
)

PACKAGES=(
    "${BASE_PACKAGES[@]}"
    "${DRIVER_PACKAGES[@]}"
    "${UI_PACKAGES[@]}"
    "${EXTRA_PACKAGES[@]}"
)

ENABLED_SERVICES=(
    NetworkManager.service
    systemd-resolved.service
    sddm.service
)

POSTINSTALL_SCRIPTS=$(cat <<EOF
set -e
echo "Enabling plymouth theme..."
plymouth-set-default-theme -R toaster
useradd -m -G wheel -s /bin/bash "$USERNAME"
echo "$USERNAME:$PASSWORD" | chpasswd
echo "Enabling sudo for wheel group..."
echo "%wheel ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers
EOF
)