#!/bin/bash

# Main script

# Calculate the path two directories up (the .config directory)
export DOTFILE_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


# Include helper functions
source "./scripts/install_helpers.sh"
# Installation directory
INSTALL_DIR="./scripts/install_scripts"

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

# Function to get yes/no input from the user (modified for -y flag)
get_yes_no_input() {
  local prompt="$1"
  local choice

  # Check for -y flag
  if [[ "$ALL_YES" == "true" ]]; then
    echo "y"  # Auto-yes if -y flag is set
    return 0
  fi

  while true; do
    read -r -p "$prompt (y/N/a for all): " choice  # Added 'a' option
    case "$choice" in
      y|Y)
        echo "y"
        return 0
        ;;
      n|N)
        echo "n"
        return 0
        ;;
      a|A)  # Handle 'a' for all
        ALL_YES="true"  # Set the flag
        echo "y" # Return y so current package will be installed
        return 0
        ;;
      *)
        warning_message "Invalid input. Please enter y, n, or a."
        ;;
    esac
  done
}

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

# Packages to install (can be extended)
packages=("neovim")

# Iterate through packages
for package in "${packages[@]}"; do
  if ! get_yes_no_input "Do you want to install $package?"; then
    info_message "Skipping $package installation."
    continue  # Skip to the next package
  fi

  install_package "$package" "$INSTALL_DIR" "$DRY_RUN"
done

echo "Installation process complete."
