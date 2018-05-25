# My Alias
alias ll='ls -al'
alias brewup='brew update && brew upgrade && brew cleanup; brew doctor; brew cask outdated'
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

if [ `lsb_release -s -c` = "xenial" ]; then
    ## antigen
    source /usr/share/zsh-antigen/antigen.zsh

    antigen bundle git
    antigen bundle golang
    antigen bundle heroku
    antigen bundle command-not-found
    antigen bundle gpg-agent
    antigen bundle docker
    antigen bundle docker-compose

    antigen bundle wbinglee/zsh-wakatime
    antigen bundle zsh-users/zsh-autosuggestions

    antigen apply

else
	## zsh-zplug
    source /usr/share/zplug/init.zsh

    zplug "plugins/git",	from:oh-my-zsh
    zplug "plugins/golang",	from:oh-my-zsh
    zplug "plugins/command-not-found",	from:oh-my-zsh
    zplug "plugins/gpg-agent",	from:oh-my-zsh
    zplug "plugins/docker",	from:oh-my-zsh
    zplug "plugins/docker-compose",	from:oh-my-zsh

    if [[ $OSTYPE == *darwin* ]]; then
      zplug "plugins/brew", from:oh-my-zsh
      zplug "plugins/osx", from:oh-my-zsh
    fi

    # Make sure to use double quotes
    zplug "zsh-users/zsh-history-substring-search"

    # Set the priority when loading
    # e.g., zsh-syntax-highlighting must be loaded
    # after executing compinit command and sourcing other plugins
    # (If the defer tag is given 2 or above, run after compinit command)
    zplug "zsh-users/zsh-syntax-highlighting", defer:2

    zplug "wbinglee/zsh-wakatime"
    zplug "zsh-users/zsh-autosuggestions"

    # Zsh plugin for installing, updating and loading nvm
    zplug "lukechilds/zsh-nvm"

    # bin
    zplug "twang2218/dotfiles", as:command, use:"bin/{qq,sss}"
  
    # Load theme file
    # zplug "skylerlee/zeta-zsh-theme", use:zeta.zsh-theme, from:github, as:theme
    # zplug "dracula/zsh", as:theme
    zplug "eendroroy/alien"
    export USE_NERD_FONT=1
    export ALIEN_BRANCH_SYM=🌵

    if ! zplug check --verbose; then
        printf "Install? [y/N]: "
        if read -q; then
            echo; zplug install
        fi
    fi


    zplug load
fi
