# Set the directory we want to store zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit, if it's not there yet
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Source/Load zinit
source "${ZINIT_HOME}/zinit.zsh"

# History setting
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory #will append history instead of rewriting over it
setopt sharehistory #will share history between multiple sessions of zsh
setopt hist_ignore_space #will not store a command if starts with space
setopt hist_ignore_all_dups #ignore all dups of a command
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups #won't come in search resul

# Add in zsh plugins, for highlishting, auto-completions and auto-suggestions
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions

bindkey '^y' autosuggest-accept
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"


# Add in snippets
# check OMZSH for more information, plugins to add snippets
# https://github.com/ohmyzsh/ohmyzsh/wiki/Plugins
zinit snippet OMZP::git  #came from https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/git

# Load completions, autoloads autocompletions for zsh-complletions
autoload -Uz compinit && compinit

# Check if the general configuration file exists
if [ -f ~/.zshrc.general ]; then
  source ~/.zshrc.general
fi

# will move it to zshrc.general as well, need to add nvim installation and config steps first
# load path of nvim bin
export PATH="$PATH:/opt/nvim-linux64/bin"

#aliases
alias ls='ls --color' # to set colors with all zsh commands
alias vim="nvim"
