#!/bin/bash

# Main script

# Calculate the path two directories up (the .config directory)
export DOTFILE_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Handle dry-run flag
DRY_RUN="false"
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN="true"
      shift
      ;;
    *)
      break  # Stop processing flags
      ;;
  esac
done

# Handle -y flag
ALL_YES="false" # Initialize
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    -y)
      ALL_YES="true"
      shift
      ;;
    *)
      break  # Stop processing flags
      ;;
  esac
done

export ALL_YES

# Include helper functions
source "./scripts/install_helpers.sh"
# Installation directory
INSTALL_DIR="./scripts/install_scripts"


# Function to ask about update/upgrade (or perform if -y is passed)
perform_update_upgrade() {
  # Check for sudo password (if needed) -  adapt as necessary
  if ! get_sudo_password; then # Assuming get_sudo_password is in install_helpers.sh
    return 1
  fi
  start_spinner "Updating package lists..."
  echo "$SUDO_PASSWORD" | sudo apt-get update > /dev/null || { stop_spinner_failure "Failed to update package list."; return 1; }
  stop_spinner_success "package lists updated."
  start_spinner "Upgrading existing packages..."
  echo "$SUDO_PASSWORD" | sudo apt-get upgrade -y > /dev/null || { stop_spinner_failure "Failed to upgrade existing packages."; return 1; }
  stop_spinner_success "package lists upgraded."
}

ask_update_upgrade() {
  if ! get_yes_no_input "Do you want to update and upgrade system packages before installation?"; then
    info_message "Skipping system update and upgrade."
    return 0
  fi

    perform_update_upgrade
  return 0
}


# Ask about update/upgrade (or perform if -y)
ask_update_upgrade

# --- Packages to install ---  (Moved this line UP!)
packages=("zsh" "neovim" "tmux" "oh-my-posh")

# Iterate through packages
for package in "${packages[@]}"; do
  if ! get_yes_no_input "Do you want to install $package?"; then
    info_message "Skipping $package installation."
    continue  # Skip to the next package
  fi

  install_package "$package" "$INSTALL_DIR" "$DRY_RUN"
done

echo "Installation process complete."
