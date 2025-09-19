#!/bin/bash

# Copy over dotfiles configs
mkdir -p ~/.config
cp -R ~/.local/share/dotfiles/config/* ~/.config/

# # Use default bashrc from dotfiles
cp ~/.local/share/dotfiles/default/bashrc ~/.bashrc
