#!/bin/bash

# Install build tools
sudo pacman -S --needed --noconfirm base-devel

# Refresh all repos
sudo pacman -Syu --noconfirm
