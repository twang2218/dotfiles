#!/bin/bash
#
# wget http://t.cn/RWiJZda -O- | /usr/bin/time -v bash
#

user_name="Tao Wang"
user_email="twang2218@gmail.com"

REPO_URL=https://raw.github.com/twang2218/dotfiles/master

export DEBIAN_FRONTEND=noninteractive

# Utils

# get distro version
distro_version=$(lsb_release -s -c)

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
		fonts-powerline \
		fonts-font-awesome \
		pv \
		git \
		jq \
		tree \
		tzdata \
		strace \
		build-essential \
		lsb-release \
		gddrescue \
		terminator

	case "$distro_version" in
		xenial)
			# gnupg 1 cannot fetch key from HTTPS, so we need gnupg-curl
			sudo apt-get install -y gnupg-curl zsh-antigen
			;;
		artful|bionic)
			# It's good to have neofetch for fun, but it's only available since 17.04
			sudo apt-get install -y neofetch zplug
			;;
	esac
}

# Graphics Driver
function install_graphics() {
	case "$1" in
		intel)	sudo apt-get install -y xserver-xorg-video-intel	;;
	esac
}

# Kernel
function install_kernel() {
	case "$distro_version" in
		xenial)
			# Let's use HWE kernel, so we will have 4.10 on Ubuntu 16.04
			sudo apt-get install -y \
				linux-generic-hwe-16.04 \
				xserver-xorg-hwe-16.04
				;;
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
	if dpkg -l | grep docker | grep -q ii; then
		echo "Docker has been installed already."
		return
	fi

	sudo addgroup --system docker
	sudo adduser $USER docker
	newgrp docker

	# curl -fsSL https://get.docker.com/ | sh -s -- --mirror Aliyun
	curl -fsSL https://get.docker.com/ | sh
}

# Virtualbox
function install_virtualbox() {
	case "$distro_version" in
		artful)
			# Ubuntu 17.10 is not supported by Virtualbox Official repo yet.
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
			wget -q -O- http://download.virtualbox.org/virtualbox/debian/oracle_vbox_2016.asc | sudo apt-key add
			sudo apt-get update
			sudo apt-get install -y virtualbox-5.2
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
	gsettings set org.gnome.desktop.interface gtk-theme "Adapta-Nokto"
	gsettings set org.gnome.desktop.interface cursor-theme "DMZ-Black"

	# Paper Icon
	sudo add-apt-repository -y ppa:snwh/pulp
	sudo apt-get update
	sudo apt-get install -y \
		paper-icon-theme \
		paper-cursor-theme
	gsettings set org.gnome.desktop.interface cursor-theme "Paper"
	gsettings set org.gnome.desktop.interface icon-theme "Paper"

	# GNOME Tweak Tools
	sudo apt-get install -y gnome-tweak-tool
}

# 中文输入法
## 安装 fcitx
function install_fcitx() {
	# Wayland is not supported by fcitx yet, so don't use it on 17.10+
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

	# 这里我们只需要 fcitx，所以删除所有 ibus 的包
	sudo apt-get purge -y "ibus*"
}

## 安装搜狗输入法
function install_sogou() {
	install_fcitx

	if dpkg -l sogoupinyin | grep -q ii; then
		echo "Sogou Pinyin has been installed already."
		return
	fi

	wget "https://pinyin.sogou.com/linux/download.php?f=linux&bit=64" -O /tmp/sogoupinyin.deb
	sudo apt install -y /tmp/sogoupinyin.deb
	rm /tmp/sogoupinyin.deb
}

## 安装 iBus 输入法
function install_ibus() {
	# 安装 Pinyin 输入法
	sudo apt-get install -y ibus-pinyin ibus-gtk3
	# 指定 pinyin 输入法
	gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'us'), ('ibus', 'pinyin')]"

	# /etc/environment
	if grep -q XMODIFIERS /etc/environment; then
		echo "IM environment variables have been added already."
		return
	fi

	cat <<EOF | sudo tee -a /etc/environment
GTK_IM_MODULE=ibus
QT_IM_MODULE=ibus
XMODIFIERS=@im=ibus
EOF

	im-config -n ibus

	# 删除 sun pinyin
	sudo apt-get purge -y ibus-sunpinyin
	# 我们只需要 ibus，所以删除所有 fcitx 相关的包。
	sudo apt-get purge -y "fcitx*"
}

# Dropbox
function install_dropbox() {
	sudo apt-key adv --keyserver pgp.mit.edu --recv-keys 5044912E
	echo "deb http://linux.dropbox.com/ubuntu/ xenial main" | sudo tee /etc/apt/sources.list.d/dropbox.list
	sudo apt-get update
	sudo apt-get install -y dropbox python-gpgme
}

# Wire
function install_wire() {
	echo "deb https://wire-app.wire.com/linux/debian stable main" | sudo tee /etc/apt/sources.list.d/wire-desktop.list
	wget -q -O- https://wire-app.wire.com/linux/releases.key | sudo apt-key add
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

# Chrome
function install_chrome() {
	echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list
	wget -q -O- https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add
	sudo apt-get update
	sudo apt-get install -y google-chrome-stable
}

# Zeal
function install_zeal() {
	if dpkg -l zeal | grep -q ii; then
		echo "Zeal has been installed already."
		return
	fi

	sudo add-apt-repository ppa:zeal-developers/ppa
	sudo apt-get update
	sudo apt-get install -y zeal
}

# Visual Studio Code
function install_vscode() {
	if dpkg -l code | grep -q ii; then
		echo "VSCode has been installed already."
		return
	fi

	# Prepare apt source
	echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" | sudo tee /etc/apt/sources.list.d/vscode.list
	wget -q -O- https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add

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
			# code --install-extension robertohuertasm.vscode-icons
			code --install-extension PKief.material-icon-theme
			code --install-extension Ikuyadeu.r
			code --install-extension itryapitsin.scala
			code --install-extension marcostazi.vs-code-vagrantfile
			# code --install-extension WakaTime.vscode-wakatime
			code --install-extension dzannotti.vscode-babel-coloring
			code --install-extension HookyQR.beautify
			code --install-extension msjsdiag.debugger-for-chrome
			code --install-extension ms-vscode.atom-keybindings
			;;
	esac
}

# Snap apps
function install_snaps() {
	sudo snap install --classic go
}

# Remove Unwanted
function remove_unwanted() {
	# Remove apport and games
	sudo apt-get purge -y apport

	# Games
	sudo apt-get purge -y gnome-sudoku
	sudo apt-get purge -y gnome-mahjongg
	sudo apt-get purge -y gnome-mines
	sudo apt-get purge -y aisleriot

	# Firefox
	sudo apt-get purge -y firefox

	# Transmission
	sudo apt-get purge -y transmission-gtk

	case "$distro_version" in
		xenial)
			# Amazon adware
			sudo apt-get purge -y unity-webapps-common
			# Other not used apps
			sudo apt-get purge -y empathy
			sudo apt-get purge -y evolution
			sudo apt-get purge -y brasero
			;;
		artful)
			# Amazon adware
			sudo apt-get purge -y ubuntu-web-launchers
			;;
	esac

	# autoremove
	sudo apt-get autoremove -y
}

# oh-my-zsh
function install_oh_my_zsh() {
	bash -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

	# Setup ZSH
	local ZSH_CUSTOM=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}

	mkdir -p $ZSH_CUSTOM/themes
	mkdir -p $ZSH_CUSTOM/plugins

	# Fetch ZSH custom script
	if [ ! -f $ZSH_CUSTOM/custom.zsh ]; then
		curl -fsSL $REPO_URL/zsh_custom.zsh -o $ZSH_CUSTOM/custom.zsh
	fi

	echo "Please run: chsh -s $(which zsh)"
}

function install_bin() {
	mkdir -p ~/bin
	curl -fsSL $REPO_URL/bin/qq -o ~/bin/qq
	curl -fsSL $REPO_URL/bin/sss -o ~/bin/sss

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
			google-chrome.desktop \
			code.desktop \
			terminator.desktop \
			yelp.desktop \
			keeweb.desktop \
			zeal.desktop \
			wire-desktop.desktop \
		)
		# We don't preserve the default apps but Nautilus
		local value=$(echo "['org.gnome.Nautilus.desktop'" $(printf ", '%s'" "${favs[@]}") "]")
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
	# install_graphics intel
	install_kernel
	install_git
	install_docker
	install_virtualbox
	install_adapta

	# 输入法选择
	case "$distro_version" in
		xenial|bionic)
			install_sogou
			;;
		artful)
			# fcitx 尚不支持 Wayland，所以只可以用 ibus
			install_ibus
			;;
	esac
	install_dropbox
	install_wire
	install_keeweb
	install_chrome
	install_vscode with_extensions
	install_zeal
	install_snaps
	remove_unwanted
	# use zplug instead
	# install_bin
	add_favorite_apps
	prepare_lab
	install_oh_my_zsh
}

main
