#!/bin/bash

# tmux.sh - Installation and configuration script for tmux

# Include helper functions (adjust path if needed)
source "$(dirname "$0")/../modules/helpers.sh"
source "$(dirname "$0")/../modules/system.sh"


# Path to your .tmux.conf template/backup
CONFIG_PATH=".tmux.conf"
TMUXCONF_SOURCE="$DOTFILE_PATH/.config/$CONFIG_PATH"
TMUXCONF_DEST="$HOME/$CONFIG_PATH"

install_tmux() {
    echo "$INSTALL_CMD"

    # Check if tmux is already installed
    if command -v tmux &> /dev/null; then
        info_message "tmux is already installed. Skipping installation."
        return 0  # Success (because it's already installed)
    fi
    
    # Check for sudo password (if needed) - adapt as necessary
    if ! get_sudo_password; then # Assuming get_sudo_password is in install_helpers.sh
        return 1
    fi

    # Check if INSTALL_CMD is set
    if [[ -z "$INSTALL_CMD" ]]; then
        error_message "INSTALL_CMD environment variable not set. Cannot proceed with installation."
        return 1
    fi
    
    # # Install tmux (using sudo if necessary)
    # start_spinner "tmux is not installed. Installing.."
    # echo "$SUDO_PASSWORD" | sudo -S dnf install -y tmux || { stop_spinner_failure "Failed to install tmux."; return 1; }
    # stop_spinner_success "tmux installed successfully."
    
    # Install tmux (using sudo)
    start_spinner "tmux is not installed. Installing.."
    if [[ "$INSTALL_CMD" =~ ^(dnf|yum)\  ]]; then
        readarray -t cmd_array < <(echo "$INSTALL_CMD" | tr ' ' '\n')
        echo "$SUDO_PASSWORD" | sudo -S "${cmd_array[0]}" "${cmd_array[@]:1}" || { stop_spinner_failure "Failed to install tmux."; return 1; }
    else
        echo "$SUDO_PASSWORD" | sudo -S "$INSTALL_CMD" || { stop_spinner_failure "Failed to install tmux."; return 1; }
    fi
    
    success_message "tmux installed successfully."
    return 0
}

install_tpm() {
    start_spinner "Installing TPM..."
    if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
        git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm || { stop_spinner_failure "Failed to clone TPM."; return 1; }
    else
        info_message "TPM already installed. Skipping installation."
    fi
    stop_spinner_success "TPM installed successfully."
    return 0
}

configure_tmux() {
    
    if [[ ! -f "$TMUXCONF_SOURCE" ]]; then
        warning_message "Source .tmux.conf file '$TMUXCONF_SOURCE' not found. Skipping .tmux.conf copy."
        return 1
    fi
    
    echo "TMUXCONF_SOURCE -> $TMUXCONF_SOURCE"
    # Use the create_symlink function to handle the symlink creation
    if ! create_symlink "$TMUXCONF_SOURCE" "$TMUXCONF_DEST"; then
        error_message "Failed to create/update .tmux.conf symlink."
        return 1
    fi
    
    # Reload tmux configuration if tmux is already running
    if tmux ls &> /dev/null; then  # Check if tmux server is running
        start_spinner "Reloading tmux configuration..."
        tmux source-file "$TMUXCONF_DEST" || { stop_spinner_failure "Failed to reload tmux configuration."; return 1; }
        stop_spinner_success "tmux configuration reloaded."
    fi
    
    return 0
}

# --- Main Script Execution ---

install_tmux

if [[ $? -eq 1 ]]; then
    exit 1
fi

install_tpm

if [[ $? -eq 1 ]]; then
    exit 1
fi

configure_tmux


echo "tmux installation and configuration complete."
