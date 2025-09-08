#!/bin/bash

DOTFILES_MIGRATIONS_STATE_PATH=~/.local/state/dotfiles/migrations
mkdir -p $DOTFILES_MIGRATIONS_STATE_PATH

for file in ~/.local/share/dotfiles/migrations/*.sh; do
  touch "$DOTFILES_MIGRATIONS_STATE_PATH/$(basename "$file")"
done
