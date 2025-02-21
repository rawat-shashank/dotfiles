#!/bin/bash

# oh-my-posh.sh - Installation script for Oh-My-Posh

# Include helper functions (adjust path if needed)
source "$(dirname "$0")/../install_helpers.sh"

install_dependencies() {
  # Array of dependencies to install
  local dependencies=("$@")

  for dep in "${dependencies[@]}"; do
    # Check if the dependency is already installed
    if command -v "$dep" &> /dev/null; then
      info_message "$dep is already installed. Skipping installation."
      continue # Go to the next dependency
    fi

    # Check for sudo password (if needed)
    if ! get_sudo_password; then
      return 1 # Exit the function if sudo password retrieval fails
    fi

    start_spinner "Installing $dep..."
    echo "$SUDO_PASSWORD" | sudo -S apt-get install -y "$dep" || { stop_spinner_failure "Failed to install $dep."; return 1; }
    stop_spinner_success "$dep installed successfully."
  done
  return 0
}

install_oh_my_posh() {
  # Check if oh-my-posh is already installed (basic check - could be improved)
  if command -v oh-my-posh &> /dev/null; then
    info_message "Oh-My-Posh is already installed. Skipping installation."
    return 0
  fi

  # Check for sudo password (if needed)
  if ! get_sudo_password; then
    return 1 # Exit the function if sudo password retrieval fails
  fi

  start_spinner "Installing Oh-My-Posh..."

  # Run the installation command
  echo "$SUDO_PASSWORD" | sudo -S curl -s https://ohmyposh.dev/install.sh | sudo bash -s -- -d /usr/bin || { stop_spinner_failure "Failed to install Oh-My-Posh."; return 1; }

  stop_spinner_success "Oh-My-Posh installed successfully."
  return 0
}

# --- Main Script Execution ---

# Install dependencies (add more dependencies to the array as needed)
# Example: install_dependencies "unzip" "other_dependency" "another_one"
install_dependencies "unzip"


install_oh_my_posh
if [[ $? -eq 0 ]]; then
  CONFIG_PATH=".config/oh-my-posh"
  create_symlink "$DOTFILE_PATH/$CONFIG_PATH" "$HOME/$CONFIG_PATH"
fi

echo "Oh-My-Posh installation and configuration complete."
