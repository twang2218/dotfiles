#!/bin/bash

TAPS=(
    caskroom/cask
    caskroom/versions
)

FORMULAS=(
    apktool
    awscli
    binwalk
    byobu
    clang-format
    curl
    docbook
    doctl
    etcd
    gcc
    git
    github-release
    gnu-sed
    gnupg2
    go
    godep
    gpg-agent
    gradle
    graphviz
    htop-osx
    imagemagick
    iperf3
    iproute2mac
    jq
    lynis
    macvim
    md5sha1sum
    media-info
    nvm
    openssl
    p7zip
    python
    python3
    qrencode
    qt
    r
    shellcheck
    tree
    uncrustify
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
    aegisub
    aliwangwang
    android-studio
    atom
    baidunetdisk
    cmb-security-plugin
    diffmerge
    disk-inventory-x
    dropbox
    evernote
    firefox
    github-desktop
    google-chrome
    google-drive
    gpgtools
    handbrake
    inkscape
    iterm2
    java
    jd-gui
    libreoffice
    licecap
    macpass
    mplayer-osx-extended
    qlvideo
    qqmusic
    rescuetime
    skyfonts
    sourcetree
    stellarium
    strongvpn-client
    textmate
    tunnelblick
    vagrant
    vagrant-manager
    virtualbox
    virtualbox-extension-pack
    visual-studio-code
    vlc
    xmind
    zazu
)

function brew() {
    # Check if Homebrew is installed
    brew=`which brew`
    if [ -z "$brew" ]; then
        echo "Installing homebrew..."
        ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    else
        echo "Homebrew already installed."
    fi

    for tap in "${TAPS[@]}"
    do
        brew tap $tap
    done

    brew install "${FORMULAS[@]}"
    brew update
    brew cask install "${CASKS[@]}"

    brew cleanup
}

function main() {
    local command=$1
    shift
    case "$command" in
        brew)   brew ;;
        *)      echo "Usage: $0 <brew>" ;;
    esac
}

main "$@"
