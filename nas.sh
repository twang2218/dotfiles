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
    htop \
    iotop \
    iftop \
    bmon \
    iptraf \
    iperf3 \
    etckeeper \
    gddrescue

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
    artful)
      cat <<EOF | sudo tee /etc/netplan/02-fixed-ip.yaml
# Fixed IP for NAS
network:
  version: 2
  renderer: networkd
  ethernets:
    enp1s0:
      dhcp4: false
      dhcp6: false
      addresses: [10.0.1.250/24]
      gateway4: 10.0.1.1
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]
      wakeonlan: true
EOF
      sudo netplan apply
      ;;
  esac
}

# ZFS
function install_zfs() {
  case "$distro_version" in
    xenial)
      sudo apt-get install -y zfs
      ;;
    artful)
      sudo apt-get install -y zfsutils-linux
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

# oh-my-zsh
function install_oh_my_zsh() {
  bash -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

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
alias docker_stats='docker stats --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}\t{{.NetIO}}\t{{.BlockIO}}\t{{.PIDs}}"'

EOF
  fi

  ## locales
  if [ ! -f $ZSH_CUSTOM/locales.zsh ]; then
    echo <<EOF | tee $ZSH_CUSTOM/locales.zsh
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
EOF
  fi

  ## zsh-antigen
  if [ ! -f $ZSH_CUSTOM/antigen.zsh ]; then
    cat <<EOF | tee $ZSH_CUSTOM/antigen.zsh
source /usr/share/zsh-antigen/antigen.zsh

antigen bundle git
antigen bundle heroku
antigen bundle command-not-found
antigen bundle docker
antigen bundle docker-compose

antigen bundle zsh-users/zsh-autosuggestions

antigen apply

EOF
  fi

  ## zsh-syntax-highlighting
  if ! grep -q "zsh-syntax-highlighting.zsh"; then
    # this should be the last line of `.zshrc`
    echo "source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" | tee -a ~/.zshrc
  fi

  echo "Please run: chsh -s $(which zsh)"
}

function main() {
  update_apt
  install_common
  install_kernel
  enable_bbr
  setup_network
  install_docker
  install_oh_my_zsh
}

main
