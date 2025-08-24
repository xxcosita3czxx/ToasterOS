# filepath: /home/cosita3cz/Warplace/toasteros/stage3/01-setup-xserver/00-run.sh
#!/bin/bash

# Create a .xinitrc file to start onboard and mousepad
cat <<EOF > /home/toaster/.xinitrc
#!/bin/bash
onboard &
exec openbox
EOF

# Make the .xinitrc file executable
chmod +x /home/toaster/.xinitrc

# Create a systemd service file to start X on boot
cat <<EOF > /etc/systemd/system/startx.service
[Unit]
Description=Start X server with onboard and mousepad
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/startx
User=toaster
Environment=DISPLAY=:0

[Install]
WantedBy=multi-user.target
EOF

# Enable the systemd service
systemctl enable startx.service
