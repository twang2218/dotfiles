# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi


# My Alias
alias ll='ls -al'
if [[ "$OSTYPE" == "*darwin*amd64*" ]]; then
  alias brewup='brew update && brew upgrade && brew cleanup; brew doctor; brew cask outdated'
fi
alias dsh='docker run -it --rm --privileged --pid=host debian nsenter -t 1 -m -u -n -i sh'
alias docker_stats='docker stats --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}\t{{.NetIO}}\t{{.BlockIO}}\t{{.PIDs}}"'

# My Functions
## 显示证书
function show_certs() {
  local server=$1
  if [ -z "$1" ]; then
    echo "Usage: show_certs www.example.com"
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
function find_latest() {
  if [ -z "$1" ]; then
    echo "Usage: find_latest <directory> [number]"
    return 1
  fi

  local num=${2:-10}

  find $1 -type f -printf '%T@ %p\n' | sort -n | tail -$num | cut -f2- -d" "
}

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


## zsh-zplug
ZPLUG_BIN=$HOME/bin
source /usr/share/zplug/init.zsh

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
    zplug "digitalocean/doctl", as:command, rename-to:doctl, use:"*linux*amd64*"
    zplug "aliyun/aliyun-cli", as:command, rename-to:aliyun, use:"*linux*amd64*"
    ;;
  darwin*)
    # macOS
    zplug "plugins/brew", from:oh-my-zsh
    zplug "plugins/osx", from:oh-my-zsh
    zplug "digitalocean/doctl", as:command, rename-to:doctl, use:"*darwin*amd64*"
    zplug "aliyun/aliyun-cli", as:command, rename-to:aliyun, use:"*darwin*amd64*"
    ;;
esac

# bin
zplug "twang2218/dotfiles", as:command, use:"bin/{qq,sss,server,domain}"

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
