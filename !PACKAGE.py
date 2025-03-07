import click
import os
import sys

os.makedirs('ToasterOS-work/DEBIAN')
os.makedirs('ToasterOS-work/opt')
def create_control_file():
    control_content = """Package: toasteros
Version: 1.0
Section: base
Priority: optional
Architecture: arm64
Depends: 
Maintainer: xxcosita3czxx <kokosove18@gmail.com>
Description: ToasterOS - A custom OS to replace Raspbian
"""
    with open('ToasterOS-work/DEBIAN/control', 'w') as control_file:
        control_file.write(control_content)

def copy_files():
    os.system('cp -r /path/to/your/os/files/* ToasterOS-work/opt/')
    os.system('cp -r /path/to/your/electron/app/* ToasterOS-work/opt/')

def build_package():
    os.system('dpkg-deb --build ToasterOS-work')

@click.command()
def main():
    create_control_file()
    copy_files()
    build_package()
    click.echo("ToasterOS installer created successfully.")

if __name__ == '__main__':
    main()