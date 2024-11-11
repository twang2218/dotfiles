# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi


######################################
##  My Alias
######################################

alias ls='ls --color=auto'
alias ll='ls -al'
if [[ "$OSTYPE" == "*darwin*amd64*" ]]; then
  alias brewup='brew update && brew upgrade && brew cleanup; brew doctor; brew cask outdated'
fi
alias dsh='docker run -it --rm --privileged --pid=host debian nsenter -t 1 -m -u -n -i sh'
alias docker_stats='docker stats --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}\t{{.NetIO}}\t{{.BlockIO}}\t{{.PIDs}}"'

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

## 寻找最新的40个文件。
find_latest() {
  if [ -z "$1" ]; then
    echo "Usage: $0 <directory> [number]"
    return 1
  fi

  local num=${2:-10}

  find $1 -type f -printf '%T@ %p\n' | sort -n | tail -$num | cut -f2- -d" "
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
    ;;
esac

# Extra
######################################
##  ZPlug
######################################

## zsh-zplug
ZPLUG_BIN=$HOME/bin

## initialize zplug
case "$OSTYPE" in
  linux*)
    export ZPLUG_HOME=/usr/share/zplug     ;;
  darwin*)
    export ZPLUG_HOME=${HOMEBREW_PREFIX}/opt/zplug ;;
esac
source $ZPLUG_HOME/init.zsh

## load plugins
zplug "plugins/git",	from:oh-my-zsh
zplug "plugins/golang",	from:oh-my-zsh
zplug "plugins/command-not-found",	from:oh-my-zsh
zplug "plugins/gpg-agent",	from:oh-my-zsh
zplug "plugins/docker",	from:oh-my-zsh
zplug "plugins/docker-compose",	from:oh-my-zsh

# Make sure to use double quotes
zplug "zsh-users/zsh-history-substring-search"

# Set the priority when loading
# e.g., zsh-syntax-highlighting must be loaded
# after executing compinit command and sourcing other plugins
# (If the defer tag is given 2 or above, run after compinit command)
zplug "zsh-users/zsh-syntax-highlighting", defer:2
zplug "zsh-users/zsh-autosuggestions"

zplug "wbinglee/zsh-wakatime"

# Rename a command with the string captured with `use` tag
zplug "b4b4r07/httpstat", \
    as:command, \
    use:'(*).sh', \
    rename-to:'$1'

case "$OSTYPE" in
  linux*)
    # linux
    zplug "digitalocean/doctl", as:command, from:gh-r, rename-to:doctl, use:"*linux*amd64*"
    zplug "aliyun/aliyun-cli", as:command, from:gh-r, rename-to:aliyun, use:"*linux*amd64*"
    ;;
  darwin*)
    # macOS
    zplug "plugins/brew", from:oh-my-zsh
    zplug "plugins/macos", from:oh-my-zsh
    zplug "digitalocean/doctl", as:command, from:gh-r, rename-to:doctl, use:"*darwin*amd64*"
    zplug "aliyun/aliyun-cli", as:command, from:gh-r, rename-to:aliyun, use:"*macosx*amd64*"
    zplug "rclone/rclone", as:command, from:gh-r, rename-to:rclone, use:"*osx*amd64*"
    ;;
esac

# bin
zplug "twang2218/dotfiles", as:command, use:"bin/{cloud,domain,drive,project,qq,server,sss}"

# Zsh plugin for installing, updating and loading nvm
export NVM_LAZY_LOAD=true
zplug "lukechilds/zsh-nvm"

# Load theme file
zplug "romkatv/powerlevel10k", as:theme, depth:1
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh


# Install plugins if there are plugins that have not been installed
if ! zplug check --verbose; then
    printf "Install? [y/N]: "
    if read -q; then
        echo; zplug install
    fi
fi


zplug load

# 显示谚语
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet
case "$OSTYPE" in
  linux*)     exec fortune-zh | cowsay -f tux -n    ;;
  darwin*)    exec fortune | cowsay -f tux -n       ;;
esac

# Anaconda

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
case "$OSTYPE" in
  linux*)   CONDA_HOME=$HOME/anaconda3      ;;
  darwin*)
    case "$CPUTYPE" in
      arm64)  CONDA_HOME=/opt/homebrew/Caskroom/miniconda/base  ;;
      *)      CONDA_HOME=/usr/local/anaconda3 ;;
    esac
    ;;
esac

__conda_setup="$('${CONDA_HOME}/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "${CONDA_HOME}/etc/profile.d/conda.sh" ]; then
        . "${CONDA_HOME}/etc/profile.d/conda.sh"
    else
        export PATH="${CONDA_HOME}/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

conda activate datascience
