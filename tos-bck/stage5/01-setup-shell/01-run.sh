on_chroot << EOF
echo "zsh" >> /home/toaster/.bashrc
echo "alias neofetch='fastfetch'" > /home/toaster/.aliases
echo "alias ls='ls --color=auto'" >> /home/toaster/.aliases
echo "alias grep='grep --color=auto'" >> /home/toaster/.aliases
echo "alias ll='ls -l'" >> /home/toaster/.aliases
echo "alias la='ls -a'" >> /home/toaster/.aliases
echo "alias l='ls -CF'" >> /home/toaster/.aliases
echo "fastfetch" >> /home/toaster/.zshrc
echo "echo ' '" >> /home/toaster/.zshrc
echo "ls" >> /home/toaster/.zshrc
echo "source /home/toaster/.aliases" >> /home/toaster/.zshrc
chsh -s /bin/zsh toaster
echo 'PROMPT="%n@%m:%d#~ "' >> /home/toaster/.zshrc
echo 'RPROMPT="%?/%t📟"' >> /home/toaster/.zshrc
EOF
