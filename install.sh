#!/bin/bash

# wget http://tinyurl.com/y94cjsmh -O- | bash
# or
# bash -c "$(wget http://tinyurl.com/y94cjsmh -O -)"

user_name="Tao Wang"
user_email="twang2218@gmail.com"

export DEBIAN_FRONTEND=noninteractive

# Utils

# get distro version
function distro_version() {
	lsb_release -s -c
}

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
		neofetch \
		lsb-release \
		gddrescue \
		terminator
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
							;;
		*)			echo "Usage: $0 (xenial)" ;;
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
	sudo addgroup --system docker
	sudo adduser $USER docker
	newgrp docker

	if [ "artful" == "$(distro_version)" ]; then
		sudo apt-get install -y docker.io
	else
		#	curl -fsSL https://get.docker.com/ | sh -s -- --mirror Aliyun
		curl -fsSL https://get.docker.com/ | sh
	fi
}

# Virtualbox
function install_virtualbox() {
	case $(distro_version) in
		artful)
						# Accept Virtualbox PUEL
						echo virtualbox-ext-pack virtualbox-ext-pack/license select true | sudo debconf-set-selections
						# Install virtualbox from Ubuntu source
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

# Adapta - Material Design theme
function install_adapta() {
	# Adapta - Material Design
	sudo add-apt-repository -y ppa:tista/adapta
	sudo apt-get update
	sudo apt-get install -y adapta-gtk-theme

	# Setting the theme
	gsettings set org.gnome.desktop.interface gtk-theme "Adapta-Nokto-Eta"
	gsettings set org.gnome.desktop.interface cursor-theme "DMZ-Black"

	if [ "artful" != "$(distro_version)" ]; then
		# Paper Icon
		sudo add-apt-repository -y ppa:snwh/pulp
		sudo apt-get update
		sudo apt-get install -y \
			paper-icon-theme \
			paper-gtk-theme \
			paper-cursor-theme
	fi

	# GNOME Tweak Tools
	sudo apt-get install -y gnome-tweak-tool
}

# 中文输入法
## 安装 fcitx
function install_fcitx() {
	if dpkg -l fcitx | grep -q ii; then
		echo "FCITX has been installed already."
		return
	fi

	sudo apt-get install -y \
		fcitx \
		fcitx-config-gtk \
		fcitx-table-all \
		fcitx-googlepinyin \
		fcitx-module-cloudpinyin \
		fcitx-pinyin \
		im-config
	im-config -n fcitx

	if grep -q XMODIFIERS /etc/environment; then
		echo "IM environment variables have been added already."
		return
	fi

	cat <<EOF | sudo tee -a /etc/environment
GTK_IM_MODULE=fcitx
QT_IM_MODULE=fcitx
XMODIFIERS=@im=fcitx
EOF

}

## 安装搜狗输入法
function install_sogou() {
	install_fcitx

	if dpkg -l sogoupinyin | grep -q ii; then
		echo "Sogou Pinyin has been installed already."
		return
	fi

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
	if dpkg -l keeweb-desktop | grep -q ii; then
		echo "KeeWeb has been installed already."
		return
	fi

	wget https://github.com/keeweb/keeweb/releases/download/v$KEEWEB_VERSION/KeeWeb-$KEEWEB_VERSION.linux.x64.deb -O /tmp/keeweb.deb
	sudo apt install -y /tmp/keeweb.deb
	rm /tmp/keeweb.deb
}

# Snap apps
function install_snaps() {
	sudo snap install zeal-casept
	sudo snap install --classic go
	sudo snap install chromium
}

function install_vscode() {
	if dpkg -l code | grep -q ii; then
		echo "VSCode has been installed already."
		return
	fi

	# Prepare apt source
	curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null
	echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" | sudo tee /etc/apt/sources.list.d/vscode.list

	# Install
	sudo apt-get update
	sudo apt-get install -y code

	# Extensions
	case $1 in
		with_extensions)
			code --install-extension ms-vscode.cpptools
			code --install-extension formulahendry.code-runner
			code --install-extension anseki.vscode-color
			code --install-extension PeterJausovec.vscode-docker
			code --install-extension Perkovec.emoji
			code --install-extension dbaeumer.vscode-eslint
			code --install-extension donjayamanne.githistory
			code --install-extension eamodio.gitlens
			code --install-extension lukehoban.go
			code --install-extension abusaidm.html-snippets
			code --install-extension shd101wyy.markdown-preview-enhanced
			code --install-extension mdickin.markdown-shortcuts
			code --install-extension DavidAnson.vscode-markdownlint
			code --install-extension PKief.material-icon-theme
			code --install-extension Ikuyadeu.r
			code --install-extension itryapitsin.scala
			code --install-extension marcostazi.vs-code-vagrantfile
			code --install-extension robertohuertasm.vscode-icons
			# code --install-extension WakaTime.vscode-wakatime
			code --install-extension dzannotti.vscode-babel-coloring
			code --install-extension HookyQR.beautify
			code --install-extension msjsdiag.debugger-for-chrome
			;;
	esac
}

# Remove Unwanted
function remove_unwanted() {
	# Remove apport and games
	sudo apt-get purge -y apport

	# Games
	sudo apt-get purge -y game-sudoku game-mahjongg game-mines aisleriot

	# Remove Amazon adware
	case $(distro_version) in
		artful)   sudo apt-get purge -y ubuntu-web-launchers ;;
		*)        sudo apt-get purge -y unity-webapps-common ;;
	esac
}

# oh-my-zsh
function install_oh_my_zsh() {
	sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
	chsh -s /bin/zsh
}

function install_bin() {
	BASEURL=https://coding.net/u/twang2218/p/dotfiles/git/raw/master
	mkdir -p ~/bin
	wget $BASEURL/bin/qq -O ~/bin/qq

	chmod u+x ~/bin/*
}

# Add favorite apps to the dock
function add_favorite_apps() {
	local current=$(gsettings get org.gnome.shell favorite-apps)
	if [[ $current == *"terminator"* ]]; then
		echo "Already added my favorite apps"
	else
		# Append following apps to the favorite apps
		local favs=( \
			terminator.desktop \
			keeweb.desktop \
			zeal-casept_zeal.desktop \
			wire-desktop.desktop \
			code.desktop \
			)
		local value=$(echo ${current%]*} $(printf ", '%s'" "${favs[@]}") "]")
		gsettings set org.gnome.shell favorite-apps "$value"
	fi
	# print the favoite apps for sure
	gsettings get org.gnome.shell favorite-apps
}

function prepare_lab() {
	mkdir -p ~/lab/go
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
	install_vscode with_extensions
	remove_unwanted
	install_bin
	add_favorite_apps
	prepare_lab
	install_oh_my_zsh
}

main