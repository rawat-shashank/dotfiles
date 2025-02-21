#!/bin/bash

# zsh.sh - Installation and configuration script for Zsh

# Include helper functions (adjust path if needed)
source "$(dirname "$0")/../install_helpers.sh"

# Path to your .zshrc template/backup
CONFIG_PATH=".zshrc"
ZSHRC_SOURCE="$DOTFILE_PATH/.config/$CONFIG_PATH"
ZSHRC_DEST="$HOME/$CONFIG_PATH"

install_zsh() {
  # Check if zsh is already installed
  if command -v zsh &> /dev/null; then
    info_message "Zsh is already installed. Skipping installation."
    return 0  # Success (because it's already installed)
  fi

  # Check for sudo password (if needed) -  adapt as necessary
  if ! get_sudo_password; then # Assuming get_sudo_password is in install_helpers.sh
    return 1
  fi

  # Install zsh (using sudo if necessary)
  start_spinner "Zsh is not installed. Installing.."
  echo "$SUDO_PASSWORD" | sudo -S apt-get install -y zsh || { stop_spinner_failure "Failed to install zsh."; return 1; }
  stop_spinner_success "Zsh installed successfully."

  success_message "Zsh installed successfully."
  return 0
}

configure_zsh() {

  if [[ ! -f "$ZSHRC_SOURCE" ]]; then
    warning_message "Source .zshrc file '$ZSHRC_SOURCE' not found. Skipping .zshrc copy."
    return 1
  fi

  # Use the create_symlink function to handle the symlink creation
  if ! create_symlink "$ZSHRC_SOURCE" "$ZSHRC_DEST"; then
    error_message "Failed to create/update .zshrc symlink."
    return 1
  fi

  # Check for sudo password (if needed) -  adapt as necessary
  if ! get_sudo_password; then # Assuming get_sudo_password is in install_helpers.sh
    return 1
  fi

  # Set zsh as the default shell (ask the user first)
  if get_yes_no_input "Do you want to set zsh as your default shell? (y/N)"; then
    start_spinner "Setting zsh as default shell..."
    echo "$SUDO_PASSWORD" | sudo chsh -s $(which zsh) "$USER" || { stop_spinner_failure "Failed to set zsh as default shell. You might need to run this command manually: 'chsh -s $(which zsh)'."; return 1; }
    stop_spinner_success "Zsh set as the default shell. You may need to open a new terminal for the changes to take effect." # Stop spinner
  fi

  return 0
}


# --- Main Script Execution ---

install_zsh

if [[ $? -eq 0 ]]; then
  configure_zsh
fi


echo "Zsh installation and configuration complete."
