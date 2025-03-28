#!/bin/bash

# zsh.sh - Installation and configuration script for Zsh

# Include helper functions (adjust path if needed)
source "$(dirname "$0")/../modules/helpers.sh"
source "$(dirname "$0")/../modules/system.sh"

# Path to your .zshrc template/backup
CONFIG_PATH=".zshrc"
ZSHRC_SOURCE="$DOTFILE_PATH/.config/$CONFIG_PATH"
ZSHRC_DEST="$HOME/$CONFIG_PATH"

install_zsh() {
    # Check for dry-run mode
    if [[ "$DRY_RUN" == "true" ]]; then
        info_message "[DRY RUN] skipping... $INSTALL_CMD will be used to install"
        return 0
    fi
    
    # Check if zsh is already installed
    if command -v zsh &> /dev/null; then
        info_message "Zsh is already installed. Skipping installation."
        return 0  # Success (because it's already installed)
    fi
    
    # Check if INSTALL_CMD is set
    if [[ -z "$INSTALL_CMD" ]]; then
        error_message "INSTALL_CMD environment variable not set. Cannot proceed with installation."
        return 1
    fi
    
    # Dry-run mode
    if [[ "$dry_run" == "true" ]]; then
        info_message "Dry-run: Would execute \"$INSTALL_CMD\""
        return 0
    fi
    
    # Check for sudo password (if needed)
    if ! get_sudo_password; then
        return 1
    fi
    
    # Install zsh (using sudo)
    start_spinner "Zsh is not installed. Installing.."
    if [[ "$INSTALL_CMD" =~ ^(dnf|yum)\  ]]; then
        readarray -t cmd_array < <(echo "$INSTALL_CMD" | tr ' ' '\n')
        echo "$SUDO_PASSWORD" | sudo -S "${cmd_array[0]}" "${cmd_array[@]:1}" || { stop_spinner_failure "Failed to install zsh."; return 1; }
    else
        echo "$SUDO_PASSWORD" | sudo -S "$INSTALL_CMD" || { stop_spinner_failure "Failed to install zsh."; return 1; }
    fi
    stop_spinner_success "Zsh installed successfully."
    return 0
}

configure_zsh() {
    # Check for dry-run mode
    if [[ "$DRY_RUN" == "true" ]]; then
        info_message "[DRY RUN] Skipping Zsh configuration (symlink and default shell)."
        return 0
    fi
    
    if [[ ! -f "$ZSHRC_SOURCE" ]]; then
        warning_message "Source .zshrc file '$ZSHRC_SOURCE' not found. Skipping .zshrc copy."
        return 1
    fi
    
    # Use the create_symlink function to handle the symlink creation
    if ! create_symlink "$ZSHRC_SOURCE" "$ZSHRC_DEST"; then
        error_message "Failed to create/update .zshrc symlink."
        return 1
    fi
    
    # Check for sudo password (if needed)
    if ! get_sudo_password; then # Assuming get_sudo_password is in system.sh
        return 1
    fi
    
    # Set zsh as the default shell (ask the user first)
    if get_yes_no_input "Do you want to set zsh as your default shell?"; then
        start_spinner "Setting zsh as default shell..."
        echo "$SUDO_PASSWORD" | sudo chsh -s $(which zsh) "$USER" || { stop_spinner_failure "Failed to set zsh as default shell. You might need to run this command manually: 'chsh -s $(which zsh)'."; return 1; }
        stop_spinner_success "Zsh set as the default shell. You may need to open a new terminal for the changes to take effect." # Stop spinner
    fi
    
    return 0
}


# --- Main Script Execution ---

install_zsh

# exit with code 1, if not installed
if [[ $? -eq 1 ]]; then
    exit "1"
fi

configure_zsh



