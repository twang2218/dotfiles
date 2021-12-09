#!/bin/bash
#
# wget http://t.cn/RWiJZda -O- | /usr/bin/time -v bash
#

user_name="Tao Wang"
user_email="twang2218@gmail.com"

REPO_URL=https://raw.github.com/twang2218/dotfiles/master

export DEBIAN_FRONTEND=noninteractive

# Common Tools
install_apt_common() {
	if [ -f /etc/apt/apt.conf.d/50no-recommends ]; then
		echo "Exists '/etc/apt/apt.conf.d/50no-recommends'"
	else
		echo "Creating '/etc/apt/apt.conf.d/50no-recommends'..."
		cat <<EOF | sudo tee /etc/apt/apt.conf.d/50no-recommends
APT::Get::Install-Recommends "false";
APT::Get::Install-Suggests "false";
EOF
	fi

	sudo apt-get update
	sudo apt-get dist-upgrade -y

	sudo apt-get install -y \
		apt-transport-https \
		curl \
		pv \
		git \
		jq \
		tree \
		tzdata \
		strace \
		build-essential \
		lsb-release \
		software-properties-common \
		gddrescue \
		inxi \
		neofetch \
		zeal \
		fzf \
		terminator
}

# Graphics Driver
install_graphics() {
	case "$1" in
		intel)	sudo apt-get install -y xserver-xorg-video-intel	;;
		nvidia)	sudo apt-get install -y nvidia-driver-470			;;
	esac
}

# Kernel
install_kernel() {
	case "$(lsb_release -s -c)" in
		focal)
			sudo apt-get install -y \
				linux-generic-hwe-20.04 \
				xserver-xorg-hwe-20.04
				;;

	esac
}

# Git
config_git() {
	local user_name=$1
	local user_email=$2
	git config --global credential.helper store
	git config --global user.name $user_name
	git config --global user.email $user_email
}

# Docker
install_docker() {
	## docker
	##   - https://docs.docker.com/engine/install/ubuntu/
	if [ $(getent group docker) ]; then
		echo "Exists group 'docker'."
	else
		echo "Adding group 'docker'..."
		sudo addgroup --system docker
		sudo adduser $USER docker
	fi

	# curl -fsSL https://get.docker.com/ | sh -s -- --mirror Aliyun

	if [ -f /etc/apt/sources.list.d/docker.list ]; then
		echo "Exists '/etc/apt/sources.list.d/docker.list'"
	else
		echo "Creating '/etc/apt/sources.list.d/docker.list'..."
		echo "deb [arch=$(dpkg --print-architecture)] https://download.docker.com/linux/ubuntu $(lsb_release -s -c) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
		curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/docker-archive-keyring.gpg
	fi

	if dpkg -l docker-ce | grep -q ii; then
		echo "Docker has been installed already."
	else
		echo "Installing Docker ..."
		sudo apt-get update
		sudo apt-get install -y docker-ce docker-ce-cli containerd.io
	fi
}

install_nvidia_docker() {
	## nvidia-docker
	##   - https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html#docker
	case "$(lsb_release -s -c)" in
		focal)
			if [ -f /etc/apt/sources.list.d/nvidia-docker.list ]; then
				echo "Exists '/etc/apt/sources.list.d/nvidia-docker.list'"
			else
				echo "Creating '/etc/apt/sources.list.d/nvidia-docker.list'..."
				distribution=ubuntu20.04
				curl -fsSL https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list
				curl -fsSL https://nvidia.github.io/nvidia-docker/gpgkey | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/nvidia-docker-archive-keyring.gpg
			fi

			if dpkg -l nvidia-docker2 | grep -q ii; then
				echo "Nvidia Docker has been installed already."
			else
				echo "Installing Nvidia Docker..."
				sudo apt-get update
				sudo apt-get install -y nvidia-docker2
				sudo systemctl restart docker
				sudo docker run --rm --gpus all nvidia/cuda:11.0-base nvidia-smi
			fi
			;;
	esac
}

# Virtualbox
install_virtualbox() {
	case "$(lsb_release -s -c)" in
		focal|hirsute)
			## virtualbox
			##   - https://www.virtualbox.org/wiki/Linux_Downloads
			if [ -f /etc/apt/sources.list.d/virtualbox.list ]; then
				echo "Exists '/etc/apt/sources.list.d/virtualbox.list'"
			else
				echo "Creating '/etc/apt/sources.list.d/virtualbox.list'..."
				echo "deb [arch=$(dpkg --print-architecture)] https://download.virtualbox.org/virtualbox/debian $(lsb_release -s -c) contrib" | sudo tee /etc/apt/sources.list.d/virtualbox.list > /dev/null
				curl -fsSL https://www.virtualbox.org/download/oracle_vbox_2016.asc | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/virtualbox-archive-keyring.gpg
			fi

			if dpkg -l | grep virtualbox | grep -q ii; then
				echo "VirtualBox has been installed already."
			else
				echo "Installing VirtualBox..."
				sudo apt-get update
				sudo apt-get install -y virtualbox-6.1
			fi
			;;
		*)
			# Accept Virtualbox PUEL
			if dpkg -l virtualbox | grep -q ii; then
				echo "VirtualBox has been installed already."
			else
				echo "Installing VirtualBox..."
				echo virtualbox-ext-pack virtualbox-ext-pack/license select true | sudo debconf-set-selections
				sudo apt-get install -y \
					virtualbox \
					virtualbox-dkms \
					virtualbox-ext-pack \
					virtualbox-guest-additions-iso
			fi
			;;
	esac
}

# 中文输入法
## 安装 fcitx
install_fcitx() {
	# Wayland is not supported by fcitx yet, so don't use it on 17.10+
	if dpkg -l fcitx | grep -q ii; then
		echo "FCITX has been installed already."
	else
		echo "Installing FCITX..."
		sudo apt-get install -y \
			fcitx \
			fcitx-config-gtk \
			fcitx-table-all \
			fcitx-googlepinyin \
			fcitx-module-cloudpinyin \
			fcitx-pinyin \
			im-config
		im-config -n fcitx
	fi

	if grep -q XMODIFIERS /etc/environment; then
		echo "IM environment variables have been added already."
	else
		echo "Adding IM environment to '/etc/environment'..."
		cat <<EOF | sudo tee -a /etc/environment
GTK_IM_MODULE=fcitx
QT_IM_MODULE=fcitx
XMODIFIERS=@im=fcitx
EOF
	fi

	# 这里我们只需要 fcitx，所以删除所有 ibus 的包
	sudo apt-get purge -y "ibus*"
}

## 安装搜狗输入法
install_sogou() {
	if dpkg -l sogoupinyin | grep -q ii; then
		echo "Sogou Pinyin has been installed already."
	else
		echo "Installing Sogou Pinyin..."
		wget "https://pinyin.sogou.com/linux/download.php?f=linux&bit=64" -O /tmp/sogoupinyin.deb
		sudo apt install -y /tmp/sogoupinyin.deb
		rm /tmp/sogoupinyin.deb
	fi
}

## 安装 iBus 输入法
install_ibus() {
	if dpkg -l ibus | grep -q ii; then
		echo "iBus has been installed already."
		return
	else
		echo "Installing iBus (with RIME)..."
	fi

	# 安装中州韻輸入法
	sudo apt-get install -y ibus-rime ibus-gtk3
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
	sudo apt-get purge -y ibus-sunpinyin

	# 我们只需要 ibus，所以删除所有 fcitx 相关的包。
	sudo apt-get purge -y "fcitx*"
}

# Dropbox
install_dropbox() {
	if dpkg -l nautilus-dropbox | grep -q ii; then
		echo "Dropbox has been installed already."
	else
		echo "Installing Dropbox..."
		sudo apt-get install -y nautilus-dropbox
	fi
}

# keeweb
install_keeweb() {
	KEEWEB_VERSION=1.18.7
	if dpkg -l keeweb-desktop | grep -q ii; then
		echo "KeeWeb has been installed already."
	else
		echo "Installing KeeWeb..."
		wget https://github.com/keeweb/keeweb/releases/download/v$KEEWEB_VERSION/KeeWeb-$KEEWEB_VERSION.linux.x64.deb -O /tmp/keeweb.deb
		sudo apt install -y /tmp/keeweb.deb
		rm /tmp/keeweb.deb
	fi
}

# Chrome
install_chrome() {
	## google chrome
	##   - https://www.google.com/linuxrepositories/
	if [ -f /etc/apt/sources.list.d/google-chrome.list ]; then
		echo "Exists '/etc/apt/sources.list.d/google-chrome.list'"
	else
		echo "Creating '/etc/apt/sources.list.d/google-chrome.list'..."
		echo "deb [arch=$(dpkg --print-architecture)] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list > /dev/null
		curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/google-chrome-archive-keyring.gpg
	fi

	if dpkg -l google-chrome-stable | grep -q ii; then
		echo "Google Chrome has been installed already."
	else
		echo "Installing Google Chrome..."
		sudo apt-get update
		sudo apt-get install -y google-chrome-stable
	fi
}

# Visual Studio Code
install_vscode() {
	## vscode
	##   - https://code.visualstudio.com/docs/setup/linux
	if [ -f /etc/apt/sources.list.d/vscode.list ]; then
		echo "Exists '/etc/apt/sources.list.d/vscode.list'"
	else
		echo "Creating '/etc/apt/sources.list.d/vscode.list'..."
		echo "deb [arch=$(dpkg --print-architecture)] https://packages.microsoft.com/repos/vscode stable main" | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
		curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/microsoft-archive-keyring.gpg
	fi

	# Install
	if dpkg -l code | grep -q ii; then
		echo "VSCode has been installed already."
	else
		echo "Installing VSCode..."
		sudo apt-get update
		sudo apt-get install -y code
	fi
}

install_via_ppa() {
	## OBS Project
	##   - https://obsproject.com/wiki/install-instructions#ubuntumint-installation
	if ls /etc/apt/sources.list.d/ | grep obsproject; then
		echo "Exists '/etc/apt/sources.list.d/obsproject.list'"
	else
		echo "Creating '/etc/apt/sources.list.d/obsproject.list'..."
		sudo add-apt-repository ppa:obsproject/obs-studio
	fi

	if dpkg -l obs-studio | grep -q ii; then
		echo "OBS project has been installed already."
	else
		echo "Installing OBS project..."
		sudo apt-get update
		sudo apt-get install -y ffmpeg obs-studio
	fi

	## qbittorrent
	##   - https://www.qbittorrent.org/download.php
	if ls /etc/apt/sources.list.d/ | grep qbittorrent; then
		echo "Exists '/etc/apt/sources.list.d/qbittorrent.list'"
	else
		echo "Creating '/etc/apt/sources.list.d/qbittorrent.list'..."
		sudo add-apt-repository ppa:qbittorrent-team/qbittorrent-stable
	fi

	if dpkg -l qbittorrent | grep -q ii; then
		echo "qbittorrent has been installed already."
	else
		echo "Installing qbittorrent..."
		sudo apt-get update
		sudo apt-get install -y qbittorrent
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
}

install_fonts() {
	if dpkg -l fonts-3270 | grep -q ii; then
		echo "fonts-nerd has been installed already."
		return
	fi

	sudo apt-get install -y \
		fonts-3270 \
		fonts-agave \
		fonts-anonymous-pro \
		ttf-bitstream-vera \
		fonts-cascadia-code \
		fonts-dejavu \
		fonts-fantasque-sans \
		fonts-firacode \
		fonts-hack-ttf \
		fonts-hermit \
		fonts-inconsolata \
		fonts-jetbrains-mono \
		fonts-liberation2 \
		fonts-monofur \
		fonts-monoid \
		fonts-mononoki \
		fonts-mplus \
		fonts-noto \
		fonts-noto-cjk \
		fonts-noto-cjk-extra \
		fonts-noto-color-emoji \
		fonts-noto-extra \
		fonts-noto-mono \
		fonts-noto-ui-core \
		fonts-noto-ui-extra \
		fonts-noto-unhinted \
		fonts-proggy \
		fonts-opendyslexic \
		fonts-roboto \
		fonts-roboto-fontface \
		fonts-roboto-slab \
		fonts-terminus \
		fonts-ubuntu \
		fonts-ubuntu-font-family-console \
		fonts-powerline \
		fonts-font-awesome

	# Install Nerd Fonts
	if [ ! -d ~/.local/share/fonts/NerdFonts ]; then
		cd /tmp/
		if [ -d nerd-fonts ]; then
			rm -rf nerd-fonts
		fi

		git clone --depth 1 https://github.com/ryanoasis/nerd-fonts.git
		cd nerd-fonts
		./install.sh \
			Arimo \
			AurulentSansMono \
			BigBlueTerminal \
			IBMPlexMono \
			CodeNewRoman \
			Cousine \
			DaddyTimeMono \
			DroidSansMono \
			FiraMono \
			Go-Mono \
			Gohu \
			Hasklig \
			HeavyData \
			iA-Writer \
			InconsolataGo \
			InconsolataLGC \
			Iosevka \
			Lekton \
			Meslo \
			ProFont \
			Overpass \
			ShareTechMono \
			SourceCodePro \
			SpaceMono \
			Tinos \
			VictorMono
	fi
}

# oh-my-zsh
install_oh_my_zsh() {
	if dpkg -l zplug | grep -q ii; then
		echo "zsh has been installed already."
	else
		echo "Installing zsh,zplug ..."
		sudo apt-get install -y zsh zplug
	fi

	if [ -d ~/.oh-my-zsh ]; then
		echo "oh-my-zsh has been installed already."
	else
		echo "Installing oh-my-zsh..."
		sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
	fi

	if [ -f ~/.oh-my-zsh/custom/custom.zsh ]; then
		echo "Exists '~/.oh-my-zsh/custom/custom.zsh'"
	else
		echo "Creating '~/.oh-my-zsh/custom/custom.zsh'..."
		# Setup ZSH
		local ZSH_CUSTOM=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}

		# Fetch ZSH custom script
		if [ ! -f $ZSH_CUSTOM/custom.zsh ]; then
			curl -fsSL $REPO_URL/zsh_custom.zsh -o $ZSH_CUSTOM/custom.zsh
			curl -fsSL $REPO_URL/zsh_p10k.zsh -o $HOME/.p10k.zsh
		fi
	fi

	install_fonts

	echo "Please run: chsh -s $(which zsh)"
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
	# Remove apport and games
	sudo apt-get purge -y apport

	# Games
	sudo apt-get purge -y \
		gnome-sudoku \
		gnome-mahjongg \
		gnome-mines \
		aisleriot

	# Transmission
	sudo apt-get purge -y transmission-gtk

	case "$(lsb_release -s -c)" in
		bionic)
			# Amazon adware
			sudo apt-get purge -y ubuntu-web-launchers
			;;
	esac

	# autoremove
	sudo apt-get autoremove -y
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
	case "$OSTYPE" in
		*darwin*)	install_macos	;;
		*linux*)	install_linux	;;
	esac
}


main
