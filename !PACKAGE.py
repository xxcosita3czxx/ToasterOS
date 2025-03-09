import os
import click
import shutil

control_content = """Package: toasteros
Version: 1.0
Section: base
Priority: optional
Architecture: arm64
Depends: libgtk-3-0, libgdk-pixbuf2.0-0, plymouth, plymouth-themes
Maintainer: xxcosita3czxx <kokosove18@gmail.com>
Description: ToasterOS is a sample package
"""

postinst_content = """#!/bin/sh
set -e

# Set the custom Plymouth theme
plymouth-set-default-theme -R toaster

# Update initramfs to apply the theme
update-initramfs -u

dpkg -i /tmp/toasteros*.deb
# Add post-install commands here
"""

@click.command()
def main():
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    shutil.rmtree('ToasterOS-work', ignore_errors=True)
    print("generating dirs")
    os.makedirs('ToasterOS-work/DEBIAN/', exist_ok=True)
    os.makedirs('ToasterOS-work/tmp/toasteros', exist_ok=True)
    os.makedirs("ToasterOS-work/usr/share/plymouth/themes/toaster/", exist_ok=True)
    print("building")
    os.system("npm run build")
    for root, dirs, files in os.walk('release'):
        for file in files:
            if file.endswith('.deb'):
                src = os.path.join(root, file)
                dst = os.path.join('ToasterOS-work', 'tmp',"toasteros", file)
                os.makedirs(os.path.dirname(dst), exist_ok=True)
                os.system(f"cp {src} {dst}")
    print("writing control files")
    control_file_path = os.path.join('ToasterOS-work', 'DEBIAN', 'control')
    with open(control_file_path, 'w') as control_file:
        control_file.write(control_content)
    postinst_file_path = os.path.join('ToasterOS-work', 'DEBIAN', 'postinst')
    with open(postinst_file_path, 'w') as postinst_file:
        postinst_file.write(postinst_content)
        os.system("chmod +x "+postinst_file_path)
    print("moving plymouth theme")
    os.system("cp -r assets/plymouth/* ToasterOS-work/usr/share/plymouth/themes/toaster")
    print("building deb")
    os.system("dpkg-deb --build ToasterOS-work")
    shutil.move('ToasterOS-work.deb', 'ToasterOS.deb')
if __name__ == '__main__':
    main()
