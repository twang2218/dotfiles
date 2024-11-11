#!/bin/zsh

######################################
##  Zinit
######################################

source /opt/homebrew/opt/zinit/zinit.zsh

# Load plugins

zinit light-mode wait lucid depth=1 for \
 atinit"ZINIT[COMPINIT_OPTS]=-C; zpcompinit; zpcdreplay" \
    zdharma-continuum/fast-syntax-highlighting \
 atload"!_zsh_autosuggest_start" \
    zsh-users/zsh-autosuggestions \
 blockf \
    zsh-users/zsh-completions

# Oh My Zsh plugins
zinit light-mode lucid for \
    OMZL::git.zsh \
    OMZL::grep.zsh \
    OMZL::history.zsh \
    OMZL::functions.zsh \
    OMZL::completion.zsh \
    OMZL::directories.zsh \
    OMZL::key-bindings.zsh

zinit light-mode wait lucid for \
    OMZP::git \
    OMZP::golang \
    OMZP::command-not-found \
    OMZP::gpg-agent \
    OMZP::docker \
    OMZP::docker-compose \
    OMZP::history \
    OMZP::gitignore \
    OMZP::common-aliases \
    OMZP::brew

# tools from GitHub
zinit light-mode as"program" from="gh-r" wait lucid for \
    digitalocean/doctl \
    aliyun/aliyun-cli \
    pick"**/rclone" rclone/rclone

zinit light-mode as"program" from="gh-r" for \
    latipun7/charasay

# dotfiles
zinit light-mode wait lucid depth=1 for \
    as"program" pick"bin/*" twang2218/dotfiles


######################################
##  My Alias
######################################

# if exists lsd command, use it
if command -v lsd > /dev/null; then
  alias l='lsd'
  alias ls='lsd'
  alias ll='lsd -l'
  alias la='lsd -la'
else
  alias l='ls -CF'
  alias ls='ls --color=auto'
  alias ll='ls -alF'
  alias la='ls -A'
fi


# remove alias for find and give rust fd command
if alias fd > /dev/null; then
  unalias fd
fi

alias dsh='docker run -it --rm --privileged --pid=host debian nsenter -t 1 -m -u -n -i sh'
alias docker_stats='docker stats --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}\t{{.NetIO}}\t{{.BlockIO}}\t{{.PIDs}}"'

######################################
##  My Environment Variables
######################################

## locales
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

## golang
export GOPATH=$HOME/lab/go
export GOBIN=$GOPATH/bin
export PATH=$PATH:$GOBIN

if [ ! -d $GOPATH ]; then
  mkdir -p $GOPATH
  mkdir -p $GOBIN
fi

## rust
export CARGO_HOME=$HOME/.cargo
export PATH=$PATH:$CARGO_HOME/bin

## python
# export PYENV_ROOT=$HOME/.pyenv
# export PATH=$PYENV_ROOT/bin:$PATH
# eval "$(pyenv init --path)"
# eval "$(pyenv init -)"
# eval "$(pyenv virtualenv-init -)"



## path
if [ ! -d $HOME/bin ]; then
  mkdir -p $HOME/bin
fi
export PATH=$PATH:$HOME/bin:$HOME/Dropbox/bin

## extra paths for macOS
case "$OSTYPE" in
  darwin*)
    ## curl
    export PATH="${HOMEBREW_PREFIX}/opt/curl/bin:$PATH"
    ## gnu-sed
    export PATH="${HOMEBREW_PREFIX}/opt/gnu-sed/libexec/gnubin:$PATH"
    ## coreutils
    export PATH="${HOMEBREW_PREFIX}/opt/coreutils/libexec/gnubin:$PATH"
    ## icu4c
    export PATH="${HOMEBREW_PREFIX}/opt/icu4c/bin:${HOMEBREW_PREFIX}/opt/icu4c/sbin:$PATH"
    export PYICU_INCLUDES="${HOMEBREW_PREFIX}/opt/icu4c/include"
    export PYICU_LFLAGS="-L${HOMEBREW_PREFIX}/opt/icu4c/lib"
    ;;
esac

######################################
##  My Functions
######################################

## 显示证书
show_certs() {
  local server=$1
  if [ -z "$1" ]; then
    echo "Usage: $0 www.example.com"
    return 1
  fi
  
  local port=${2:-443}
  echo \
    | openssl s_client \
      -showcerts \
      -servername "$server" \
      -connect "$server:$port" \
      2>/dev/null \
    | openssl x509 -inform pem -noout -text
}

# backup photography folder to external disk
backup_photo() {
  # TODO: find src and dest automatically, and add confirmation option
  # rsync -avP /Volumes/LaCie/user/Tao/Photo/ /Volumes/private/tao/Photography/Tao
  # rsync -avP /Volumes/LaCie/user /Volumes/8TB_DISK_MAC/
  local src=${1:-/Volumes/2TB_USB_WD/user/Tao/Photo/}
  local dest=${2:-/Volumes/private-1/Photography/TaoPhoto}
  
  time rsync -rtpogvz --progress --delete $src $dest
}

# convert input video into GIF animation
2gif() {
  local src=$1
  local dest=$2

  if [ -z "$src" -o -z "$dest" ]; then
    echo "Usage: $0 <src> <dest>"
    return 1
  fi

  ffmpeg -i "$src" \
    -vf scale=320:-1 \
    -r 10 \
    -f image2pipe \
    -vcodec ppm - \
    | convert -delay 5 -loop 0 - "$dest"
}

# convert a batch jpg files into 4k video, which is useful for timelapse video creating
jpg2video4k() {
  local src=$1
  local dest=${2:-output.mp4}

  if [ -z "$src" -o -z "$dest" ]; then
    echo "Usage: $0 <jpg_dir> <output.mp4>"
    return 1
  fi

  ffmpeg -i "$src/*.jpg" \
    -pattern_type glob \
    -an \
    -r 24 \
    -c:v libx264 \
    -filter:v scale="3840:trunc(ow/a/2)*2" \
    -pix_fmt yuv420p \
    -profile:v high \
    -b:v 70M \
    "$dest"
}

# convert a batch jpg files into 1080 video, which is useful for timelapse video creating
jpg2video2k() {
  local src=$1
  local dest=${2:-output.mp4}

  if [ -z "$src" -o -z "$dest" ]; then
    echo "Usage: $0 <jpg_dir> <output.mp4>"
    return 1
  fi

  ffmpeg -i "$src/*.jpg" \
    -pattern_type glob \
    -an \
    -r 24 \
    -c:v libx264 \
    -filter:v scale="1920:trunc(ow/a/2)*2" \
    -pix_fmt yuv420p \
    -profile:v high \
    -b:v 10M \
    "$dest"
}

# stablize the video
video_stable() {
  local src=$1

  if [ -z "$src" ]; then
    echo "Usage: $0 <input.mp4> [input.stable.mp4]"
    return 1
  fi

  local src_name="${src%.*}"
  local src_ext="${src##*.}"
  local dest=${2:-$src_name.stable.$src_ext}

  ffmpeg -i $src -vf vidstabdetect=shakiness=10:accuracy=15 -f null -
  ffmpeg -i $src -vf vidstabtransform=smoothing=30,unsharp=5:5:0.8:3:3:0.4 -strict -2 $dest
  rm transforms.trf
}

# stablize the video (with tripod in use)
video_stable_tripod() {
  local src=$1

  if [ -z "$src" ]; then
    echo "Usage: $0 <input.mp4> [input.stable.mp4]"
    return 1
  fi

  local src_name="${src%.*}"
  local src_ext="${src##*.}"
  local dest=${2:-$src_name.stable.$src_ext}

  ffmpeg -i $src -vf vidstabdetect=shakiness=10:accuracy=15:tripod=1 -f null -
  ffmpeg -i $src -vf vidstabtransform=tripod=1,unsharp=5:5:0.8:3:3:0.4 $dest
  rm transforms.trf
}

merge4video() {
  ffmpeg.exe -i $1 -i $2 -i $3 -i $4 \
    -filter_complex "[0:0]scale=iw/2:ih/2,pad=iw*2:ih*2[a];[1:0]scale=iw/2:ih/2[b];[2:0]scale=iw/2:ih
/2[c];[3:0]scale=iw/2:ih/2[d];[a][b]overlay=w[x];[x][c]overlay=0:h[y];[y][d]overlay=w:h,drawtext=fontsize=12:fontcolor=white:fontfil
e=Arial:text='$6':x=35:y=35,drawtext=fontsize=12:fontcolor=white:fontfile=Arial:text='$7':x=(w/2)+35:y=35,drawtext=fontsize=12:fontc
olor=white:fontfile=Arial:text='$8':x=35:y=(h/2)+35,drawtext=fontsize=12:fontcolor=white:fontfile=Arial:text='$9':x=(w/2)+35:y=(h/2)
+35" \
  $5
}

# Add given subtitle to the video
video_add_sub() {
  local video_file=$1
  local sub_file=$2

  if [ -z "$video_file" -o -z "$sub_file" ]; then
    echo "Usage: $0 <video_file> <sub_file> [output_file]"
    return 1
  fi

  local output_file=${3:-${video_file%.*}.sub.mp4}

  # ffmpeg cannot handle ASS with filename contains "[", so copy it to a temp file with basic file name.
  local temp_file=$(mktemp)
  cp "$sub_file" "$temp_file"
  ffmpeg -i "$video_file" -preset slow -crf 22 -vf "ass=$temp_file" "$output_file"
  rm "$temp_file"
}

# launch a Tor browser
torbrowser() {
  docker run -it \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -e DISPLAY=unix$DISPLAY \
    --device /dev/snd \
    --name tor-browser \
    jess/tor-browser

  docker logs -f tor-browser

  docker rm tor-browser
}



######################################
##  Prompt
######################################

# prompt
eval "$(starship init zsh)"
# generic package manager
eval "$(mise activate zsh)"


######################################
##  fortune cookie
######################################

# 显示谚语
# typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet
case "$OSTYPE" in
  linux*)     exec fortune-zh | chara say -r   ;;
  darwin*)    exec fortune | chara say -r      ;;
esac
