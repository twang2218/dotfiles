#!/bin/bash

distro_version=$(lsb_release -s -c)

# Update
sudo apt-get update
sudo apt-get dist-upgrade -y

# Common Tools
sudo apt-get install -y --no-install-recommends \
	apt-transport-https \
	curl \
	zsh \
	pv \
	git \
	jq \
	tree \
	tzdata \
	strace \
	gddrescue \
	terminator \
	smartmontools

# Graphics Driver
sudo apt-get install -y xserver-xorg-video-intel

# Ubuntu 16.04
# sudo apt-get install -y --install-recommends linux-generic-hwe-16.04 xserver-xorg-hwe-16.04

# Docker
curl https://get.docker.com/ | sh
sudo usermod -aG docker $user
newgrp docker

# Virtualbox
echo "deb http://download.virtualbox.org/virtualbox/debian $(distro_version) contrib" | sudo tee /etc/apt/sources.list.d/virtualbox.list
sudo apt-get update
sudo apt-get install -y virtualbox-5.2

# adapta - Material Design theme
sudo add-apt-repository -y ppa:tista/adapta
sudo add-apt-repository -y ppa:snwh/pulp
sudo apt-get update
sudo apt-get install -y \
	adapta-gtk-theme \
	paper-icon-theme \
	paper-gtk-theme \
	paper-cursor-theme

# 中文输入法
sudo apt-get install fcitx fcitx-config-gtk fcitx-table-all im-config
wget https://pinyin.sogou.com/linux/download.php?f=linux&bit=64 -O /tmp/sogoupinyin.deb
sudo apt install -y /tmp/sogoupinyin.deb
rm /tmp/sogoupinyin.deb

# Wire
wget -q https://wire-app.wire.com/linux/releases.key -O- | sudo apt-key add -
echo "deb https://wire-app.wire.com/linux/debian stable main" | sudo tee /etc/apt/sources.list.d/wire-desktop.list
sudo apt-get update
sudo apt-get install -y wire-desktop

# keeweb
KEEWEB_VERSION=1.5.6
wget https://github.com/keeweb/keeweb/releases/download/v$KEEWEB_VERSION/KeeWeb-$KEEWEB_VERSION.linux.x64.deb -O /tmp/keeweb.deb
sudo apt install -y /tmp/keeweb.deb
rm /tmp/keeweb.deb

# Remove apport
sudo apt-get remove -y apport

# Snap apps

## Zeal
sudo snap install zeal-casept
sudo snap install --classic vscode
sudo snap install --classic go
sudo snap install chromium

# oh-my-zsh
sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"


