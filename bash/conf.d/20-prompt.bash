# Custom Bash prompt configuration with Catppuccin Macchiato color palette and Nerd Fonts

# Catppuccin Macchiato Color Palette (RGB Escape Sequences)
CLR_ROSEWATER='\[\e[38;2;244;219;214m\]'
CLR_FLAMINGO='\[\e[38;2;240;198;198m\]'
CLR_PINK='\[\e[38;2;245;189;230m\]'
CLR_MAUVE='\[\e[38;2;198;160;246m\]'
CLR_RED='\[\e[38;2;237;135;150m\]'
CLR_MAROON='\[\e[38;2;238;153;160m\]'
CLR_PEACH='\[\e[38;2;245;169;127m\]'
CLR_YELLOW='\[\e[38;2;229;200;144m\]'
CLR_GREEN='\[\e[38;2;166;209;137m\]'
CLR_TEAL='\[\e[38;2;139;213;202m\]'
CLR_SKY='\[\e[38;2;145;215;227m\]'
CLR_SAPPHIRE='\[\e[38;2;125;196;228m\]'
CLR_BLUE='\[\e[38;2;138;173;244m\]'
CLR_LAVENDER='\[\e[38;2;183;189;248m\]'
CLR_SUBTEXT0='\[\e[38;2;165;173;203m\]'
CLR_RESET='\[\e[0m\]'

# Raw ANSI color sequences for use inside parse_git_status function
RAW_MAUVE='\e[38;2;198;160;246m'
RAW_PEACH='\e[38;2;245;169;127m'
RAW_RED='\e[38;2;237;135;150m'
RAW_YELLOW='\e[38;2;229;200;144m'
RAW_GREEN='\e[38;2;166;209;137m'
RAW_RESET='\e[0m'

parse_git_status() {
  if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    return 0
  fi

  local branch
  branch=$(git symbolic-ref --short HEAD 2>/dev/null) ||
    branch=$(git rev-parse --short HEAD 2>/dev/null) || return 0

  local status_flags=""
  local git_status
  git_status=$(git status --porcelain 2>/dev/null)

  if [[ -n $(echo "$git_status" | grep -E '^\?\?') ]]; then
    status_flags+="󰋗 " # Untracked
  fi
  if [[ -n $(echo "$git_status" | grep -E '^.[MADU]') ]]; then
    status_flags+="󰏫 " # Modified
  fi
  if [[ -n $(echo "$git_status" | grep -E '^[MADRC]') ]]; then
    status_flags+="󰐕 " # Staged
  fi
  if git rev-parse --verify refs/stash &>/dev/null; then
    status_flags+="󰏗 " # Stashed
  fi

  local upstream
  if upstream=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null); then
    local diff
    diff=$(git rev-list --left-right --count HEAD..."${upstream}" 2>/dev/null)
    local ahead=$(echo "$diff" | awk '{print $1}')
    local behind=$(echo "$diff" | awk '{print $2}')

    [[ "$ahead" -gt 0 ]] && status_flags+="󰞁${ahead} "
    [[ "$behind" -gt 0 ]] && status_flags+="󰞂${behind} "
  fi

  status_flags="${status_flags%" "}"

  if [[ -n "$status_flags" ]]; then
    echo -e " (${RAW_YELLOW}󰘬 ${branch}${RAW_RESET} ${RAW_RED}${status_flags}${RAW_RESET})"
  else
    echo -e " (${RAW_GREEN}󰘬 ${branch}${RAW_RESET})"
  fi
}

# Terminal prompt mapping Catppuccin palette elements
# User/Host (Blue) | Directory (Lavender) | Git (Peach/Green/Red) | Symbol (Mauve)
PS1="${CLR_PINK} \u@\h${CLR_RESET} ${CLR_LAVENDER} \w${CLR_RESET}\$(parse_git_status) ${CLR_MAUVE}\n\$${CLR_RESET} "
