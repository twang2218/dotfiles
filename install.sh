#!/bin/bash
#
# wget http://t.cn/RWiJZda -O- | /usr/bin/time -v bash
#

user_name="Tao Wang"
user_email="twang2218@gmail.com"

REPO_URL=https://raw.github.com/twang2218/dotfiles/master

export DEBIAN_FRONTEND=noninteractive

apt_install() {
	sudo apt-get update
	local pkgs=()
	for pkg in "$@"; do
		if dpkg -l $pkg 2> /dev/null | grep -q ii ; then
			echo "[Found] package '$pkg'"
		else
			pkgs+=("$pkg")
		fi
	done

	if [ -n "$pkgs" ]; then
		echo "[Installing] '${pkgs[@]}'..."
		sudo apt-get install -y "${pkgs[@]}"
	fi
}

apt_remove() {
	local pkgs=()
	for pkg in "$@"; do
		if dpkg -l $pkg 2> /dev/null | grep -q ii ; then
			pkgs+=("$pkg")
		else
			echo "[Not Installed] package '$pkg'"
		fi
	done

	if [ -n "$pkgs" ]; then
		echo "[Removing] '${pkgs[@]}'..."
		sudo apt-get purge --quiet -y "${pkgs[@]}"
		sudo apt-get autoremove -y
	fi
}

# Common Tools
command_packages=(
	apt-transport-https
	curl
	pv
	git
	jq
	tree
	build-essential
	gddrescue
	inxi
	neofetch
	zeal
	fzf
	fortunes-zh
	cowsay
	byobu
	htop
	terminator
	variety
	awscli
)

install_apt_common() {
	echo "[Installing] common packages..."
	if [ -f /etc/apt/apt.conf.d/50no-recommends ]; then
		echo "[Found] '/etc/apt/apt.conf.d/50no-recommends'"
	else
		echo "[Creating] '/etc/apt/apt.conf.d/50no-recommends'..."
		cat <<EOF | sudo tee /etc/apt/apt.conf.d/50no-recommends
APT::Get::Install-Recommends "false";
APT::Get::Install-Suggests "false";
EOF
	fi

	apt_install "${command_packages[@]}"
}

remove_apt_common() {
	echo "[Removing] common packages..."
	if [ ! -f /etc/apt/apt.conf.d/50no-recommends ]; then
		echo "[Not Found] '/etc/apt/apt.conf.d/50no-recommends'"
	else
		echo "[Removing] '/etc/apt/apt.conf.d/50no-recommends'..."
		sudo rm /etc/apt/apt.conf.d/50no-recommends
	fi
	apt_remove "${command_packages[@]}"
}

# Graphics Driver
install_graphics() {
	echo "[Installing] Graphics Driver <$1>..."
	case "$1" in
		intel)	apt_install xserver-xorg-video-intel	;;
		nvidia)	apt_install nvidia-driver-470			;;
	esac
}

remove_graphics() {
	echo "[Removing] Graphics Driver <$1>..."
	case "$1" in
		intel)	apt_remove xserver-xorg-video-intel	;;
		nvidia)	apt_remove nvidia-driver-470			;;
	esac

}

# Kernel
install_kernel() {
	echo "[Installing] Kernel..."
	case "$(lsb_release -s -c)" in
		focal)	apt_install linux-generic-hwe-20.04 xserver-xorg-hwe-20.04	;;
	esac
}

remove_kernel() {
	echo "[Removing] Kernel..."
	case "$(lsb_release -s -c)" in
		focal)	apt_remove linux-generic-hwe-20.04 xserver-xorg-hwe-20.04	;;
	esac
}

# Git
config_git() {
	echo "[Setting] git config..."
	local user_name=$1
	local user_email=$2

	if ! git config --global user.name ; then
		git config --global credential.helper store
		git config --global user.name $user_name
		git config --global user.email $user_email
	fi
	git config --global --list
}

# Docker
install_docker() {
	echo "[Installing] Docker..."
	## docker
	##   - https://docs.docker.com/engine/install/ubuntu/
	if [ $(getent group docker) ]; then
		echo "[Exists] group 'docker'."
	else
		echo "[Adding] group 'docker'..."
		sudo addgroup --system docker
		sudo adduser $USER docker
	fi

	# curl -fsSL https://get.docker.com/ | sh -s -- --mirror Aliyun

	docker_prerequisite_packages=(
		apt-transport-https
		ca-certificates
		curl
		gnupg-agent
		software-properties-common
	)
	apt_install "${docker_prerequisite_packages[@]}"

	if [ -f /etc/apt/sources.list.d/docker.list ]; then
		echo "[Exists] '/etc/apt/sources.list.d/docker.list'"
	else
		echo "[Creating] '/etc/apt/sources.list.d/docker.list'..."
		echo "deb [arch=$(dpkg --print-architecture)] https://download.docker.com/linux/ubuntu $(lsb_release -s -c) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
		curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/docker-archive-keyring.gpg
	fi

	apt_install docker-ce docker-ce-cli containerd.io

	if [[ ! -z "$DOCKER_MIRROR" ]]; then
		echo 'Setup Docker Hub mirror'
		if [[ -f /etc/docker/daemon.json ]]; then
			sudo mv /etc/docker/daemon.json /etc/docker/daemon.json.backup
		fi
		echo "{\"registry-mirrors\": [\"$DOCKER_MIRROR\"]}" | sudo tee /etc/docker/daemon.json
	fi

	sudo systemctl enable docker
	sudo systemctl restart docker

	docker info
}

remove_docker() {
	echo "[Removing] Docker..."
	apt_remove docker-ce docker-ce-cli containerd.io

	if [ ! -f /etc/apt/sources.list.d/docker.list ]; then
		echo "[Not Found] '/etc/apt/sources.list.d/docker.list'"
	else
		echo "[Removing] '/etc/apt/sources.list.d/docker.list'..."
		sudo rm /etc/apt/sources.list.d/docker.list
		sudo rm /etc/apt/trusted.gpg.d/docker-archive-keyring.gpg
	fi
}

install_nvidia_docker() {
	echo "[Installing] Nvidia Docker..."
	## nvidia-docker
	##   - https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html#docker
	case "$(lsb_release -s -c)" in
		focal)
			if [ -f /etc/apt/sources.list.d/nvidia-docker.list ]; then
				echo "[Exists] '/etc/apt/sources.list.d/nvidia-docker.list'"
			else
				echo "[Creating] '/etc/apt/sources.list.d/nvidia-docker.list'..."
				distribution=ubuntu20.04
				curl -fsSL https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list
				curl -fsSL https://nvidia.github.io/nvidia-docker/gpgkey | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/nvidia-docker-archive-keyring.gpg
			fi

			apt_install nvidia-docker2
			sudo systemctl restart docker
			sudo docker run --rm --gpus all nvidia/cuda:11.0-base nvidia-smi
			;;
	esac
}

remove_nvidia_docker() {
	echo "[Removing] Nvidia Docker..."
	if [ ! -f /etc/apt/sources.list.d/nvidia-docker.list ]; then
		echo "[Not Found] '/etc/apt/sources.list.d/nvidia-docker.list'"
	else
		echo "[Removing] '/etc/apt/sources.list.d/nvidia-docker.list'..."
		sudo rm /etc/apt/sources.list.d/nvidia-docker.list
		sudo rm /etc/apt/trusted.gpg.d/nvidia-docker-archive-keyring.gpg
	fi

	apt_remove nvidia-docker2
}

# Virtualbox
virtualbox_packages=(
	virtualbox
	virtualbox-dkms
	virtualbox-ext-pack
	virtualbox-guest-additions-iso
)

install_virtualbox() {
	echo "[Installing] VirtualBox..."
	case "$(lsb_release -s -c)" in
		focal|hirsute)
			## virtualbox
			##   - https://www.virtualbox.org/wiki/Linux_Downloads
			if [ -f /etc/apt/sources.list.d/virtualbox.list ]; then
				echo "[Exists] '/etc/apt/sources.list.d/virtualbox.list'"
			else
				echo "[Creating] '/etc/apt/sources.list.d/virtualbox.list'..."
				echo "deb [arch=$(dpkg --print-architecture)] https://download.virtualbox.org/virtualbox/debian $(lsb_release -s -c) contrib" | sudo tee /etc/apt/sources.list.d/virtualbox.list > /dev/null
				curl -fsSL https://www.virtualbox.org/download/oracle_vbox_2016.asc | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/virtualbox-archive-keyring.gpg
			fi

			apt_install virtualbox-6.1
			;;
		*)
			# Accept Virtualbox PUEL
			echo virtualbox-ext-pack virtualbox-ext-pack/license select true | sudo debconf-set-selections
			apt_install "${virtualbox_packages[@]}"
			;;
	esac
}

remove_virtualbox() {
	echo "[Removing] VirtualBox..."
	case "$(lsb_release -s -c)" in
		focal|hirsute)
			if [ ! -f /etc/apt/sources.list.d/virtualbox.list ]; then
				echo "[Not Found] '/etc/apt/sources.list.d/virtualbox.list'"
			else
				echo "[Removing] '/etc/apt/sources.list.d/virtualbox.list'..."
				sudo rm /etc/apt/sources.list.d/virtualbox.list
				sudo rm /etc/apt/trusted.gpg.d/virtualbox-archive-keyring.gpg
			fi

			apt_remove virtualbox-6.1
			;;
		*)
			apt_remove "${virtualbox_packages[@]}"
			;;
	esac
}

# 中文输入法
## 安装 fcitx
fcitx_packages=(
	fcitx
	fcitx-config-gtk
	fcitx-table-all
	fcitx-googlepinyin
	fcitx-module-cloudpinyin
	fcitx-pinyin
)

install_fcitx() {
	echo "[Installing] FCITX..."
	if dpkg -l fcitx | grep -q ii; then
		echo "[Exists] fcitx has been installed already."
		return
	fi

	# Wayland is not supported by fcitx yet, so don't use it on 17.10+
	apt_install "${fcitx_packages[@]}"
	apt_install im-config
	im-config -n fcitx

	if grep -q XMODIFIERS /etc/environment; then
		echo "[Exists] IM environment variables have been added already."
	else
		echo "[Adding] IM environment to '/etc/environment'..."
		cat <<EOF | sudo tee -a /etc/environment
GTK_IM_MODULE=fcitx
QT_IM_MODULE=fcitx
XMODIFIERS=@im=fcitx
EOF
	fi

	# 这里我们只需要 fcitx，所以删除所有 ibus 的包
	sudo apt-get purge -y "ibus*"
}

remove_fcitx() {
	echo "[Removing] FCITX..."
	apt_remove "${fcitx_packages[@]}"
}

## 安装搜狗输入法
install_sogou() {
	echo "[Installing] Sogou Pinyin..."
	if dpkg -l sogoupinyin | grep -q ii; then
		echo "[Exists] Sogou Pinyin has been installed already."
	else
		echo "[Installing] sogoupinyin..."
		wget "https://pinyin.sogou.com/linux/download.php?f=linux&bit=64" -O /tmp/sogoupinyin.deb
		sudo apt install -y /tmp/sogoupinyin.deb
		rm /tmp/sogoupinyin.deb
	fi
}

remove_sogou() {
	echo "[Removing] Sogou Pinyin..."
	apt_remove sogoupinyin
}

## 安装 iBus 输入法
install_ibus() {
	echo "[Installing] iBus (with RIME)..."
	# 安装中州韻輸入法
	apt_install ibus-rime ibus-gtk3

	# 指定 rime 输入法
	gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'us'), ('ibus', 'rime')]"

	# /etc/environment
	# if grep -q XMODIFIERS /etc/environment; then
	# 	echo "IM environment variables have been added already."
	# 	return
	# fi

# 	cat <<EOF | sudo tee -a /etc/environment
# GTK_IM_MODULE=ibus
# QT_IM_MODULE=ibus
# XMODIFIERS=@im=ibus
# EOF

	im-config -n ibus

	# 删除 sun pinyin
	apt_remove ibus-sunpinyin

	# 我们只需要 ibus，所以删除所有 fcitx 相关的包。
	apt_remove "fcitx*"
}

remove_ibus() {
	echo "[Removing] iBus..."
	apt_remove ibus-rime
}

# Dropbox
install_dropbox() {
	apt_install nautilus-dropbox
}

remove_dropbox() {
	apt_remove nautilus-dropbox
}

# KeeWeb
install_keeweb() {
	KEEWEB_VERSION=1.18.7
	echo "[Installing] KeeWeb ($KEEWEB_VERSION)..."
	if dpkg -l keeweb-desktop | grep -q ii; then
		echo "[Exists] KeeWeb has been installed already."
	else
		echo "[Installing] keeweb-desktop..."
		wget https://github.com/keeweb/keeweb/releases/download/v$KEEWEB_VERSION/KeeWeb-$KEEWEB_VERSION.linux.x64.deb -O /tmp/keeweb.deb
		sudo apt install -y /tmp/keeweb.deb
		rm /tmp/keeweb.deb
	fi
}

remove_keeweb() {
	echo "[Removing] KeeWeb..."
	apt_remove keeweb-desktop
}

# Chrome
install_chrome() {
	echo "[Installing] Google Chrome..."
	## google chrome
	##   - https://www.google.com/linuxrepositories/
	if [ -f /etc/apt/sources.list.d/google-chrome.list ]; then
		echo "[Exists] '/etc/apt/sources.list.d/google-chrome.list'"
	else
		echo "[Creating] '/etc/apt/sources.list.d/google-chrome.list'..."
		echo "deb [arch=$(dpkg --print-architecture)] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list > /dev/null
		curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/google-chrome-archive-keyring.gpg
	fi

	apt_install google-chrome-stable
}

remove_chrome() {
	echo "[Removing] Google Chrome..."
	if [ ! -f /etc/apt/sources.list.d/google-chrome.list ]; then
		echo "[Not Found] '/etc/apt/sources.list.d/google-chrome.list'"
	else
		echo "[Removing] '/etc/apt/sources.list.d/google-chrome.list'..."
		sudo rm /etc/apt/sources.list.d/google-chrome.list
		sudo rm /etc/apt/trusted.gpg.d/google-chrome-archive-keyring.gpg
	fi

	apt_remove google-chrome-stable
}

# Visual Studio Code
install_vscode() {
	echo "[Installing] Visual Studio Code..."
	## vscode
	##   - https://code.visualstudio.com/docs/setup/linux
	if [ -f /etc/apt/sources.list.d/vscode.list ]; then
		echo "[Exists] '/etc/apt/sources.list.d/vscode.list'"
	else
		echo "[Creating] '/etc/apt/sources.list.d/vscode.list'..."
		echo "deb [arch=$(dpkg --print-architecture)] https://packages.microsoft.com/repos/vscode stable main" | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
		curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/microsoft-archive-keyring.gpg
	fi

	# Install
	apt_install code
}

remove_vscode() {
	echo "[Removing] Visual Studio Code..."
	if [ ! -f /etc/apt/sources.list.d/vscode.list ]; then
		echo "[Not Found] '/etc/apt/sources.list.d/vscode.list'"
	else
		echo "[Removing] '/etc/apt/sources.list.d/vscode.list'..."
		sudo rm /etc/apt/sources.list.d/vscode.list
		sudo rm /etc/apt/trusted.gpg.d/microsoft-archive-keyring.gpg
	fi

	apt_remove code
}

install_via_ppa() {
	## OBS Project
	##   - https://obsproject.com/wiki/install-instructions#ubuntumint-installation
	echo "[Installing] Open Broadcaster Software Studio..."
	if ls /etc/apt/sources.list.d/ | grep obsproject; then
		echo "[Exists] ppa:obsproject/obs-studio"
	else
		echo "[Adding] ppa:obsproject/obs-studio..."
		sudo add-apt-repository -y ppa:obsproject/obs-studio
		apt_install ffmpeg
		apt_install obs-studio
	fi

	## qbittorrent
	##   - https://www.qbittorrent.org/download.php
	echo "[Installing] qbittorrent..."
	if ls /etc/apt/sources.list.d/ | grep qbittorrent; then
		echo "[Exists] ppa:qbittorrent-team/qbittorrent-stable"
	else
		echo "[Adding] ppa:qbittorrent-team/qbittorrent-stable..."
		sudo add-apt-repository -y ppa:qbittorrent-team/qbittorrent-stable
		apt_install qbittorrent
	fi
}

remove_via_ppa() {
	echo "[Removing] Open Broadcaster Software Studio..."
	if ls /etc/apt/sources.list.d/ | grep obsproject; then
		echo "[Removing] ppa:obsproject/obs-studio..."
		sudo add-apt-repository --remove -y ppa:obsproject/obs-studio
		apt_remove obs-studio
	else
		echo "[Not Found] ppa:obsproject/obs-studio..."
	fi

	echo "[Removing] qbittorrent..."
	if ls /etc/apt/sources.list.d/ | grep qbittorrent; then
		echo "[Removing] ppa:qbittorrent-team/qbittorrent-stable..."
		sudo add-apt-repository --remove -y ppa:qbittorrent-team/qbittorrent-stable
		apt_remove qbittorrent
	else
		echo "[Not Found] ppa:qbittorrent-team/qbittorrent-stable..."
	fi
}

# Snap apps
install_via_snaps() {
	sudo snap refresh
	sudo snap install --classic go
	sudo snap install --classic flutter
	sudo snap install wire
	sudo snap install icalingua
	sudo snap install telegram-desktop
	sudo snap install vlc
	sudo snap install qqmusic-snap
}

remove_via_snaps() {
	sudo snap refresh
	sudo snap remove go
	sudo snap remove flutter
	sudo snap remove wire
	sudo snap remove icalingua
	sudo snap remove telegram-desktop
	sudo snap remove vlc
	sudo snap remove qqmusic-snap
}

fonts_packages=(
	fonts-3270
	fonts-agave
	fonts-anonymous-pro
	ttf-bitstream-vera
	fonts-cascadia-code
	fonts-dejavu
	fonts-fantasque-sans
	fonts-firacode
	fonts-hack-ttf
	fonts-hermit
	fonts-inconsolata
	fonts-jetbrains-mono
	fonts-liberation2
	fonts-monofur
	fonts-monoid
	fonts-mononoki
	fonts-mplus
	fonts-noto
	fonts-noto-cjk
	fonts-noto-cjk-extra
	fonts-noto-color-emoji
	fonts-noto-extra
	fonts-noto-mono
	fonts-noto-ui-core
	fonts-noto-ui-extra
	fonts-noto-unhinted
	fonts-proggy
	fonts-opendyslexic
	fonts-roboto
	fonts-roboto-fontface
	fonts-roboto-slab
	fonts-terminus
	# fonts-ubuntu
	fonts-ubuntu-font-family-console
	fonts-powerline
	fonts-font-awesome
)

fonts_nerd_other_names=(
	Arimo
	AurulentSansMono
	BigBlueTerminal
	IBMPlexMono
	CodeNewRoman
	Cousine
	DaddyTimeMono
	DroidSansMono
	FiraMono
	Go-Mono
	Gohu
	Hasklig
	HeavyData
	iA-Writer
	InconsolataGo
	InconsolataLGC
	Iosevka
	Lekton
	Meslo
	ProFont
	Overpass
	ShareTechMono
	SourceCodePro
	SpaceMono
	Tinos
	VictorMono
)

install_fonts() {
	echo "[Installing] Nerd Fonts..."
	apt_install "${fonts_packages[@]}"

	# Install Nerd Fonts
	if [ -d $HOME/.local/share/fonts/NerdFonts ]; then
		echo "[Exists] Nerd Fonts folder - $HOME/.local/share/fonts/NerdFonts"
		du -sh "$HOME/.local/share/fonts/NerdFonts"
	else
		echo "[Installing] Nerd Fonts - $HOME/.local/share/fonts/NerdFonts..."
		if [ -d /tmp/nerd-fonts ]; then
			rm -rf /tmp/nerd-fonts
		fi

		git clone --depth 1 https://github.com/ryanoasis/nerd-fonts.git /tmp/nerd-fonts

		cd /tmp/nerd-fonts
		./install.sh "${fonts_nerd_other_names[@]}"
	fi
}

remove_fonts() {
	if [ ! -d $HOME/.local/share/fonts/NerdFonts ]; then
		echo "[Not Found] Nerd Fonts folder - $HOME/.local/share/fonts/NerdFonts"
	else
		echo "[Removing] Nerd Fonts - $HOME/.local/share/fonts/NerdFonts..."
		du -sh "$HOME/.local/share/fonts/NerdFonts"
		rm -rf $HOME/.local/share/fonts/NerdFonts
	fi

	apt_remove "${fonts_packages[@]}"
}

# oh-my-zsh
install_oh_my_zsh() {
	echo "[Installing] ZSH shell..."
	apt_install zsh zplug

	if [ -d $HOME/.oh-my-zsh ]; then
		echo "[Found] oh-my-zsh has been installed already."
	else
		echo "[Installing] oh-my-zsh..."
		RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
	fi

	if [ -f $HOME/.oh-my-zsh/custom/custom.zsh ]; then
		echo "[Exists] '$HOME/.oh-my-zsh/custom/custom.zsh'"
	else
		echo "[Creating] '$HOME/.oh-my-zsh/custom/custom.zsh'..."
		# Setup ZSH
		local ZSH_CUSTOM=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}

		# Fetch ZSH custom script
		if [ ! -f $ZSH_CUSTOM/custom.zsh ]; then
			if [ -f zsh_custom.zsh ]; then
				# copy from local
				cp zsh/custom.zsh $ZSH_CUSTOM/custom.zsh
				cp zsh/.p10k.zsh $HOME/.p10k.zsh
				cp zsh/p10k-instant-prompt-local.zsh $HOME/.cache/p10k-instant-prompt-local.zsh
			else
				# fetch from repo
				curl -fsSL $REPO_URL/zsh/custom.zsh -o $ZSH_CUSTOM/custom.zsh
				curl -fsSL $REPO_URL/zsh/.p10k.zsh -o $HOME/.p10k.zsh
				curl -fsSL $REPO_URL/zsh/p10k-instant-prompt-local.zsh -o $HOME/.cache/p10k-instant-prompt-local.zsh
			fi
		fi
	fi

	install_fonts

	echo "Please run: chsh -s $(which zsh)"
}

remove_oh_my_zsh() {
	if [ ! -f $HOME/.oh-my-zsh/custom/custom.zsh ]; then
		echo "[Not Found] custom zsh script"
	else
		echo "[Removing] custom zsh script..."
		rm $ZSH_CUSTOM/custom.zsh
		rm $HOME/.p10k.zsh
		rm $HOME/.cache/p10k-instant-prompt-*.zsh
	fi

	if [ ! -d $HOME/.oh-my-zsh ]; then
		echo "[Not Found] oh-my-zsh has been installed already."
	else
		echo "[Removing] oh-my-zsh..."
		env ZSH="$HOME/.oh-my-zsh" sh "$ZSH/tools/uninstall.sh"
	fi

	if [ -d $HOME/.oh-my-zsh ]; then
		rm -rf $HOME/.oh-my-zsh
	fi

	if [ -d $HOME/.zplug ]; then
		rm -rf $HOME/.zplug
	fi

	remove_fonts
}

# Add favorite apps to the dock
gnome_dock_favorite_apps() {
	local current=$(gsettings get org.gnome.shell favorite-apps)
	if [[ $current == *"keeweb"* ]]; then
		echo "Already added my favorite apps to gnome dock"
	else
		# the favorite apps
		local favs=( \
			firefox_firefox.desktop \
			org.gnome.Nautilus.desktop \
			keeweb.desktop \
			org.gnome.Terminal.desktop \
			code.desktop \
		)
		# We don't preserve the default apps but Nautilus
		local value=$(echo "[" $(printf ", '%s'" "${favs[@]}") "]")
		gsettings set org.gnome.shell favorite-apps "$value"
	fi
	# print the favoite apps for sure
	gsettings get org.gnome.shell favorite-apps
}

# Remove Unwanted
cleanup() {
	# Remove apport, games and transmission
	apt_remove apport \
		gnome-sudoku \
		gnome-mahjongg \
		gnome-mines \
		aisleriot \
		transmission-gtk

	case "$(lsb_release -s -c)" in
		bionic)
			# Amazon adware
			apt_remove ubuntu-web-launchers
			;;
	esac
}

install_linux() {
	install_apt_common
	install_graphics intel
	install_graphics nvidia
	install_kernel

	# 输入法选择
	case "$(lsb_release -s -c)" in
		xenial|focal)
			install_fcitx
			install_sogou
			;;
		*)
			# fcitx 尚不支持 Wayland，所以只可以用 ibus
			install_ibus
			;;
	esac


	install_oh_my_zsh
	install_docker
	install_nvidia_docker
	install_virtualbox
	install_dropbox
	install_keeweb
	install_chrome
	install_vscode

	install_via_ppa
	install_via_snaps


	config_git $user_name $user_email
	gnome_dock_favorite_apps

	cleanup
}

remove_linux() {
	remove_apt_common
	remove_graphics intel
	remove_graphics nvidia
	remove_kernel
	remove_oh_my_zsh

	remove_docker
	remove_nvidia_docker
	remove_virtualbox
	remove_dropbox
	remove_keeweb
	remove_chrome
	remove_vscode

	remove_via_ppa
	remove_via_snaps
}


install_macos() {
	TAPS=(
		caskroom/cask
		caskroom/versions
	)

	FORMULAS=(
		aliyun-cli
		apktool
		awscli
		binwalk
		curl
		doctl
		git
		gnu-sed
		gnupg2
		go
		gpg-agent
		graphviz
		htop-osx
		iperf3
		iproute2mac
		jq
		macvim
		md5sha1sum
		media-info
		nvm
		openssl
		p7zip
		python3
		qrencode
		r
		shellcheck
		tree
		wakatime-cli
		webp
		wget
		xz
		yarn
		youtube-dl
		zsh
	)

	CASKS=(
		adobe-dng-converter
		aliwangwang
		baidunetdisk
		diffmerge
		disk-inventory-x
		dropbox
		firefox
		google-chrome
		google-drive
		gpgtools
		handbrake
		iterm2
		java
		jd-gui
		libreoffice
		qqmusic
		rescuetime
		skyfonts
		sourcetree
		stellarium
		visual-studio-code
		vlc
		xmind
	)

	# https://brew.sh/
	if [ -n "$(which brew)" ]; then
		echo "Homebrew has been installed already."
	else
        echo "Installing Homebrew..."
		/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

		for tap in "${TAPS[@]}"
		do
			brew tap $tap
		done
	fi


    brew install "${FORMULAS[@]}"
    brew update
    brew cask install "${CASKS[@]}"

    brew cleanup
}

main() {
	case "$1" in
		remove)
			case "$OSTYPE" in
				*darwin*)	remove_macos	;;
				*linux*)	remove_linux	;;
			esac
			;;
		install)
			case "$OSTYPE" in
				*darwin*)	install_macos	;;
				*linux*)	install_linux	;;
			esac
			;;
	esac
}


main "$@"
