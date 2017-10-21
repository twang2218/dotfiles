#!/bin/bash

# wget http://tinyurl.com/y94cjsmh -O- | sh

user_name="Tao Wang"
user_email="twang2218@gmail.com"

# Update
function update_apt() {
	sudo apt-get update
	sudo apt-get dist-upgrade -y
}

function config_apt() {
	cat <<EOF | sudo tee /etc/apt/apt.conf.d/50no-recommends
APT::Get::Install-Recommends "false";
APT::Get::Install-Suggests "false";
EOF
}

# get distro version
function distro_version() {
	lsb_release -s -c
}

# Common Tools
function install_common() {
	sudo apt-get install -y \
		apt-transport-https \
		curl \
		zsh \
		pv \
		git \
		jq \
		tree \
		tzdata \
		strace \
		build-essential \
		lsb-release \
		gddrescue \
		terminator \
		smartmontools
}

# Graphics Driver
function install_graphics() {
	case $1 in
		intel)	sudo apt-get install -y xserver-xorg-video-intel	;;
		*)			echo "Usage: $0 (intel)"	;;
	esac
}

# Kernel
function install_kernel() {
	case $(distro_version) in
		xenial)
						sudo apt-get install -y \
							linux-generic-hwe-16.04 \
							xserver-xorg-hwe-16.04
		*)			echo "Usage: $0 (xenial)"
	esac
}

# Git
function install_git() {
	local user_name=$1
	local user_email=$2
	git config --global credential.helper store
	git config --global user.name $user_name
	git config --global user.email $user_email
}

# Docker
function install_docker() {
	#	curl -fsSL https://get.docker.com/ | sh -s -- --mirror Aliyun
	curl -fsSL https://get.docker.com/ | sh
	sudo addgroup --system docker
	sudo adduser $USER docker
	newgrp docker
}

# Virtualbox
function install_virtualbox() {
	case $(distro_version) in
		artful)
						sudo apt-get install -y \
							virtualbox \
							virtualbox-dkms \
							virtualbox-ext-pack \
							virtualbox-guest-additions-iso
						;;
		*)
						echo "deb http://download.virtualbox.org/virtualbox/debian $distro_version contrib" \
							| sudo tee /etc/apt/sources.list.d/virtualbox.list
						sudo apt-get install -y \
							virtualbox-5.2
						;;
	esac
}

# adapta - Material Design theme
function install_adapta() {
	sudo add-apt-repository -y ppa:tista/adapta
	sudo apt-get update
	sudo apt-get install -y adapta-gtk-theme

	if [ "artful" == "$(distro_version)" ]; then
		sudo add-apt-repository -y ppa:snwh/pulp
		sudo apt-get update
		sudo apt-get install -y \
			paper-icon-theme \
			paper-gtk-theme \
			paper-cursor-theme
	fi
}

# 中文输入法

## 安装 fcitx
function install_fcitx() {
	sudo apt-get install -y \
		fcitx \
		fcitx-config-gtk \
		fcitx-table-all \
		fcitx-googlepinyin \
		fcitx-module-cloudpinyin \
		fcitx-pinyin \
		im-config
	im-config -n fcitx

	if ! grep -q XMODIFIERS /etc/environment; then
		cat <<EOF | sudo tee -a /etc/environment
GTK_IM_MODULE=fcitx
QT_IM_MODULE=fcitx
XMODIFIERS=@im=fcitx
EOF
	fi
}

## 安装搜狗输入法
function install_sogou() {
	install_fcitx

	wget https://pinyin.sogou.com/linux/download.php?f=linux&bit=64 -O /tmp/sogoupinyin.deb
	sudo apt install -y /tmp/sogoupinyin.deb
	rm /tmp/sogoupinyin.deb
}

## 安装 iBus 输入法
function install_ibus() {
	sudo apt-get install -y \
		ibus-pinyin
}

# Wire
function install_wire() {
	wget -q https://wire-app.wire.com/linux/releases.key -O- | sudo apt-key add -
	echo "deb https://wire-app.wire.com/linux/debian stable main" | sudo tee /etc/apt/sources.list.d/wire-desktop.list
	sudo apt-get update
	sudo apt-get install -y wire-desktop
}

# keeweb
function install_keeweb() {
	KEEWEB_VERSION=1.5.6
	wget https://github.com/keeweb/keeweb/releases/download/v$KEEWEB_VERSION/KeeWeb-$KEEWEB_VERSION.linux.x64.deb -O /tmp/keeweb.deb
	sudo apt install -y /tmp/keeweb.deb
	rm /tmp/keeweb.deb
}

# Snap apps
function install_snaps() {
	sudo snap install zeal-casept
	sudo snap install --classic vscode
	sudo snap install --classic go
	sudo snap install chromium
}

# Remove Unwanted
function remove_unwanted() {
	# Remove apport
	sudo apt-get remove -y apport
}

# oh-my-zsh
function install_oh_my_zsh() {
	sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
}

function main() {
	update_apt
	config_apt
	install_common
	install_graphics intel
	install_kernel
	install_git
	install_docker
	install_virtualbox
	install_adapta
	install_ibus
	install_wire
	install_keeweb
	install_snaps
	remove_unwanted
	install_oh_my_zsh
}

main