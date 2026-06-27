#!/bin/bash

ansi_art='

██████╗  ██████╗ ████████╗███████╗██╗██╗     ███████╗███████╗
██╔══██╗██╔═══██╗╚══██╔══╝██╔════╝██║██║     ██╔════╝██╔════╝
██║  ██║██║   ██║   ██║   █████╗  ██║██║     █████╗  ███████╗
██║  ██║██║   ██║   ██║   ██╔══╝  ██║██║     ██╔══╝  ╚════██║
██████╔╝╚██████╔╝   ██║   ██║     ██║███████╗███████╗███████║
╚═════╝  ╚═════╝    ╚═╝   ╚═╝     ╚═╝╚══════╝╚══════╝╚══════╝

'

clear
echo -e "\n$ansi_art\n"

pacman -Syu --noconfirm --needed git

# Use custom repo if specified, otherwise default to basecamp/dotfiles
DOTFILES_REPO="${DOTFILES_REPO:-rawat-shashank/dotfiles}"

# echo -e "\nCloning Omarchy from: https://github.com/${DOTFILES_REPO}.git"
rm -rf ~/.local/share/dotfiles/
git clone "https://github.com/${DOTFILES_REPO}.git" $HOME/.local/share/dotfiles >/dev/null

# Use custom branch if instructed, otherwise default to master
DOTFILES_REF="${DOTFILES_REF:-main}"
if [[ $DOTFILES_REF != "main" ]]; then
  echo -e "\eUsing branch: $DOTFILES_REF"
  cd ~/.local/share/dotfiles
  git fetch origin "${DOTFILES_REF}" && git checkout "${DOTFILES_REF}"
  cd -
fi

echo -e "\nInstallation starting..."
source ~/.local/share/dotfiles/install.sh
