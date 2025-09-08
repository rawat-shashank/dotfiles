#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -eE

DOTFILES_PATH="$HOME/.local/share/dotfiles"
DOTFILES_INSTALL="$DOTFILES_PATH/install"
export PATH="$DOTFILES_PATH/bin:$PATH"

# Preparation
source $DOTFILES_INSTALL/helpers/confirm.sh
source $DOTFILES_INSTALL/preflight/guard.sh
source $DOTFILES_INSTALL/preflight/pacman.sh
source $DOTFILES_INSTALL/preflight/migrations.sh

# Packaging
source $DOTFILES_INSTALL/packages.sh

# Configuration
source $DOTFILES_INSTALL/config/config.sh
