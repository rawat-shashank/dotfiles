#!/bin/bash

# Determine the OS
if [[ -n "$WSL_DISTRO_NAME" ]]; then
  bash ubuntu.sh
# elif [[ "$OSTYPE" == "linux-gnu" ]]; then
#   bash ubuntu.sh
# elif [[ "$OSTYPE" == "darwin" ]]; then
#   zsh mac.sh
else
    echo "Aborting... Unknown OS"
    exit 1
fi

