import os
import click
import shutil

control_content = """Package: ToasterOS
Version: 1.0
Section: base
Priority: optional
Architecture: arm64
Depends: libgtk-3-0, libgdk-pixbuf2.0-0, plymouth, plymouth-themes, xscreensaver, xscreensaver-data-extra, xscreensaver-gl-extra
Maintainer: xxcosita3czxx <kokosove18@gmail.com>
Description: ToasterOS is a sample package
"""

postinst_content = """#!/bin/sh
set -e

# Set the custom Plymouth theme
plymouth-set-default-theme -R toaster

# Update initramfs to apply the theme
update-initramfs -u

# Force the installation to bypass dpkg file lock
dpkg --force-all -i /tmp/toasteros*.deb

echo " b"

# Add post-install commands here
USER_HOME=$(eval echo ~$USER)
mv /tmp/toaster/ToasterOS $USER_HOME/.config/ToasterOS

# Check if /boot/firmware/config.txt exists
if [ -f /boot/firmware/config.txt ]; then
    # Disable the rainbow splash by adding the line
    echo "disable_splash=1" >> /boot/firmware/config.txt
fi

"""

config_content ="""IMG_NAME=ToasterOS.img
PI_GEN_RELEASE=ToasterOS
TARGET_HOSTNAME=ToasterOS
TIMEZONE_DEFAULT=Europe/Prague
DISABLE_FIRST_BOOT_USER_RENAME=1
FIRST_USER_NAME=toaster
FIRST_USER_PASS=toaster
STAGE_LIST="stage0 stage1 stage2 stage3 stage4"
CLEAN=1
LOG_FILE="${WORK_DIR}/../../build.log"
"""

@click.command()
def main():
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    shutil.rmtree('ToasterOS-work', ignore_errors=True)
    shutil.rmtree('pi-gen/stage6', ignore_errors=True)
    print("generating dirs")
    os.makedirs("pi-gen/stage6/files", exist_ok=True)
    os.makedirs('ToasterOS-work/DEBIAN/', exist_ok=True)
    os.makedirs('ToasterOS-work/tmp/toasteros/ToasterOS/setup', exist_ok=True)
    os.makedirs("ToasterOS-work/usr/share/plymouth/themes/toaster/", exist_ok=True)
    os.makedirs("ToasterOS-work/usr/share/icons/toaster/", exist_ok=True)
    print("moving plymouth theme")
    os.system("cp -r assets/plymouth/* ToasterOS-work/usr/share/plymouth/themes/toaster")
    print("moving setup files")
    os.system("cp -r assets/stage6/* pi-gen/stage6")
    os.system("cp -r Setup/* ToasterOS-work/tmp/toasteros/ToasterOS/setup")
    os.system("cp ToasterOS-work/tmp/toasteros/ToasterOS/setup/logo.jpg ToasterOS-work/usr/share/icons/toaster/logo.jpg")
    os.system("cp ToasterOS-work/tmp/toasteros/ToasterOS/setup/logo-transparent.png ToasterOS-work/usr/share/icons/toaster/logo-transparent.png")
    print("writing control files")
    os.system("cp -r pi-gen ToasterOS-work")
    control_file_path = os.path.join('ToasterOS-work', 'DEBIAN', 'control')
    with open(control_file_path, 'w') as control_file:
        control_file.write(control_content)
    postinst_file_path = os.path.join('ToasterOS-work', 'DEBIAN', 'postinst')
    with open(postinst_file_path, 'w') as postinst_file:
        postinst_file.write(postinst_content)
        os.system("chmod +x "+postinst_file_path)
    config_file_path = os.path.join('ToasterOS-work', "pi-gen", "config")
    with open(config_file_path, "w") as config_file:
        config_file.write(config_content)
    print("building app")
    os.chdir("App")
    os.system("npm run build")
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    for root, dirs, files in os.walk('App/release'):
        for file in files:
            if file.endswith('.deb'):
                src = os.path.join(root, file)
                dst = os.path.join('ToasterOS-work', 'tmp',"toasteros", file)
                os.makedirs(os.path.dirname(dst), exist_ok=True)
                os.system(f"cp {src} {dst}")
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    print("building deb")
    os.system("dpkg-deb --build ToasterOS-work")
    shutil.move('ToasterOS-work.deb', 'ToasterOS.deb')
    shutil.move("ToasterOS.deb", "pi-gen/stage6/files/ToasterOS.deb")
    # Create SKIP_IMAGE files in stages before stage6
    for stage in ['stage0', 'stage1', 'stage2', 'stage3', 'stage4', 'stage5']:
        skip_image_path = os.path.join('pi-gen', stage, 'SKIP_IMAGES')
        with open(skip_image_path, 'w') as skip_image_file:
            skip_image_file.write('')
    with open('pi-gen/stage5/SKIP', 'w') as skip_image_file:
        skip_image_file.write('')
    if os.path.exists('pi-gen/work'):
        for stage in ['stage0', 'stage1', 'stage2', 'stage3', 'stage4', 'stage5']:
            skip_image_path = os.path.join('pi-gen', stage, 'SKIP')
            with open(skip_image_path, 'w') as skip_image_file:
                skip_image_file.write('')
    os.chdir("pi-gen")
    os.system("sudo ./build.sh")
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    shutil.move("pi-gen/work/*/toasteros_*.zip", "ToasterOS.zip")
    print("done")

if __name__ == '__main__':
    main()
