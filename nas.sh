#!/bin/bash
#
# wget http://t.cn/RWR4kfg -O- | /usr/bin/time -v bash
#

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
		zsh-antigen \
		zsh-syntax-highlighting \
		pv \
		git \
		jq \
		tree \
		tzdata \
		strace \
		gddrescue \

	case "$distro_version" in
		xenial)
			# gnupg 1 cannot fetch key from HTTPS, so we need gnupg-curl
			sudo apt-get install -y gnupg-curl
			;;
		artful)
			# It's good to have neofetch for fun, but it's only available since 17.04
			sudo apt-get install -y neofetch
			;;
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

# BBR
function enable_bbr() {
  echo 'net.core.default_qdisc=fq' >> /etc/sysctl.conf
  echo 'net.ipv4.tcp_congestion_control=bbr' >> /etc/sysctl.conf
}

# IP Address
function setup_network() {
  case "$distro_version" in
    artful)
      cat <<EOF | sudo tee /etc/netplan/02-fixed-ip.yaml
# Fixed IP for NAS
network:
  version: 2
  renderer: networkd
  ethernets:
    enp1s0:
      dhcp4: no
      dhcp6: no
      addresses: [10.0.1.250/24]
      gateway4: 10.0.1.1
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]
EOF
      sudo netplan apply
      ;;
    xenial)
      sudo mkdir -p /etc/network/interfaces.d
      cat <<EOF | sudo tee /etc/network/interfaces.d/20-fixed-ip.cfg
# Fixed IP for NAS
auto enp1s0
iface enp1s0 inet static
  address 10.0.1.250
  dns-nameservers 8.8.8.8 8.8.4.4
  gateway 10.0.1.1
  netmask 255.255.255.0
EOF
      ;;
  esac
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

	case "$distro_version" in
		artful)
			# Ubuntu 17.10 is not supported by Docker CE
			# So use docker.io (1.13) instead.
			sudo apt-get install -y docker.io
			;;
		*)
			#	curl -fsSL https://get.docker.com/ | sh -s -- --mirror Aliyun
			curl -fsSL https://get.docker.com/ | sh
			;;
	esac
}

function main() {
	update_apt
	install_common
	install_kernel
  enable_bbr
  setup_network
	install_docker
}

main
