#!/bin/bash
#
# wget http://t.cn/RWiJZda -O- | bash
#

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
		zsh-antigen \
		zsh-syntax-highlighting \
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
	# 安装 Pinyin 输入法
	sudo apt-get install -y ibus-pinyin
	# 替换 sunpinyin 输入法
	local old_sources="$(gsettings get org.gnome.desktop.input-sources sources)"
	local new_sources="$(echo $old_sources | sed -s 's/sunpinyin/pinyin/g')"
	gsettings set org.gnome.desktop.input-sources sources "$new_sources"
	echo "New IM Sources: $new_sources"
	# 删除 sun pinyin
	sudo apt-get purge -y ibus-sunpinyin
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

# Chrome
function install_chrome() {
	echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list
	curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
	sudo apt-get update
	sudo apt-get install -y google-chrome-stable
}

# Snap apps
function install_snaps() {
	sudo snap install zeal-casept
	sudo snap install --classic go
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

	# Remove Firefox
	sudo apt-get purge -y firefox
}

# oh-my-zsh
function install_oh_my_zsh() {
	bash -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
	chsh -s $(which zsh)

	# Setup ZSH
	local ZSH_CUSTOM=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}

	mkdir -p $ZSH_CUSTOM/themes
	mkdir -p $ZSH_CUSTOM/plugins

	## Theme
	if [ ! -f $ZSH_CUSTOM/zeta_theme.zsh ]; then
		wget https://raw.githubusercontent.com/skylerlee/zeta-zsh-theme/master/zeta.zsh-theme -O $ZSH_CUSTOM/themes/zeta.zsh-theme
		echo 'ZSH_THEME="zeta"' > $ZSH_CUSTOM/zeta_theme.zsh
	fi

	## Alias
	if [ ! -f $ZSH_CUSTOM/alias.zsh ]; then
		cat <<EOF | tee $ZSH_CUSTOM/alias.zsh
# My Alias

alias ll='ls -al'
alias brewup='brew update && brew upgrade && brew cleanup; brew doctor; brew cask outdated'
alias dsh='docker run -it --rm --privileged --pid=host debian nsenter -t 1 -m -u -n -i sh'
alias docker_stats='docker stats --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}\t{{.NetIO}}\t{{.BlockIO}}\t{{.PIDs}}"'

EOF
	fi

	## locales
	if [ ! -f $ZSH_CUSTOM/locales.zsh ]; then
		echo <<EOF | tee $ZSH_CUSTOM/locales.zsh
export LANG=en_AU.UTF-8
export LC_ALL=en_AU.UTF-8
EOF
	fi

	## golang
	if [ ! -f $ZSH_CUSTOM/golang.zsh ]; then
		mkdir -p ~/lab/go
		echo <<EOF | tee $ZSH_CUSTOM/golang.zsh
export GOPATH=$HOME/lab/go
export GOBIN=$GOPATH/bin
export PATH=$PATH:$GOBIN
EOF
	fi

	## path
	if [ ! -f $ZSH_CUSTOM/path.zsh ]; then
		mkdir -p ~/bin
		echo "export PATH=$PATH:$HOME/bin:$HOME/Dropbox/bin" | tee $ZSH_CUSTOM/path.zsh
	fi

	## zsh-antigen
	if [ ! -f $ZSH_CUSTOM/antigen.zsh ]; then
		cat <<EOF | tee $ZSH_CUSTOM/antigen.zsh
source /usr/share/zsh-antigen/antigen.zsh

antigen bundle git
antigen bundle golang
antigen bundle heroku
antigen bundle command-not-found
antigen bundle gpg-agent
antigen bundle docker
antigen bundle docker-compose

if [ "$(uname)" = "Darwin" ]; then
	antigen bundle brew
	antigen bundle osx
fi

if [ "$(lsb_release -si)" = "Ubuntu" ]; then
	antigen bundle ubuntu
fi

antigen bundle wbinglee/zsh-wakatime
antigen bundle zsh-users/zsh-autosuggestions

antigen apply

EOF
	fi

	## zsh-syntax-highlighting
	if ! grep -q "zsh-syntax-highlighting.zsh"; then
		# this should be the last line of `.zshrc`
		echo "source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" | tee -a ~/.zshrc
	fi
}

function install_bin() {
	BASEURL=https://coding.net/u/twang2218/p/dotfiles/git/raw/master
	mkdir -p ~/bin
	wget $BASEURL/bin/qq -O ~/bin/qq
	wget $BASEURL/bin/ss -O ~/bin/ss

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
			zeal-casept_zeal.desktop \
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
	install_graphics intel
	install_kernel
	install_git
	install_docker
	install_virtualbox
	install_adapta
	install_ibus
	install_wire
	install_keeweb
	install_chrome
	install_vscode with_extensions
	install_snaps
	remove_unwanted
	install_bin
	add_favorite_apps
	prepare_lab
	install_oh_my_zsh
}

main
