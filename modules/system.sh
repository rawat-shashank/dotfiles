#!/bin/bash

# Source helpers for message functions
source "./modules/helpers.sh"
source "./modules/input.sh"

# Function to get sudo password if needed and store it in SUDO_PASSWORD
get_sudo_password() {
    if [[ $UID -ne 0 ]]; then # Check if NOT root
        if [[ -z "$SUDO_PASSWORD" ]]; then # Check if SUDO_PASSWORD is already set (important!)
            read -s -p "This script requires sudo. Enter your password: " SUDO_PASSWORD
            echo ""  # Add a newline
            export SUDO_PASSWORD # Make it available to subshells
        fi
        return 0
    fi
    return 0 # If already root, no password needed
}

get_base_os() {
    if [[ -f /etc/debian_version ]]; then
        echo "Debian"
        elif [[ -f /etc/redhat-release ]]; then
        echo "RedHat"
        elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macOS"
        elif [[ -f /etc/arch-release ]]; then
        echo "Arch" # Example for future expansion
    else
        echo "Unknown"
    fi
}

get_os_command() {
    local action="$1"
    local package="$2"
    local base_os=$(get_base_os)
    
    case "$base_os" in
        Debian)
            case "$action" in
                install) echo "apt install -y $package";;
                update) echo "apt update";;
                upgrade) echo "apt upgrade -y";;
                check_installed) echo "dpkg -s $package";;
                *) echo "";; # Return empty string for unknown action
            esac
        ;;
        RedHat)
            local package_manager=$(if command -v dnf &> /dev/null; then echo "dnf"; else echo "yum"; fi)
            case "$action" in
                install) echo "$package_manager install -y $package";;
                update) echo "$package_manager update";;
                upgrade) echo "$package_manager upgrade -y";;
                check_installed) echo "rpm -q $package";;
                *) echo "";;
            esac
        ;;
        macOS)
            case "$action" in
                install) echo "brew install $package";;
                update) echo "brew update";;
                upgrade) echo "brew upgrade";;
                check_installed) echo "brew list $package";;
                *) echo "";;
            esac
        ;;
        Arch) # Example for future expansion
            case "$action" in
                install) echo "pacman -S --noconfirm $package";;
                update) echo "pacman -Syu";;
                upgrade) echo "";; # Arch generally updates and upgrades with the same command
                check_installed) echo "pacman -Q $package";;
                *) echo "";;
            esac
        ;;
        *)
            echo ""; # Return empty string for unknown OS
        ;;
    esac
}

perform_update_upgrade() {
    
    # Check for sudo password
    if ! get_sudo_password; then
        return 1
    fi
    
    local update_cmd=$(get_os_command "update")
    local upgrade_cmd=$(get_os_command "upgrade")
    local base_os=$(get_base_os)
    
    case "$base_os" in
        macOS)
            if [[ -n "$update_cmd" ]]; then
                if [[ "$DRY_RUN" == "true" ]]; then
                    info_message "[DRY RUN] Would run: brew update"
                else
                    start_spinner "Updating Homebrew..."
                    brew update &> /dev/null || { stop_spinner_failure "Failed to update Homebrew."; return 1; }
                    stop_spinner_success "Homebrew updated."
                fi
            fi
            if [[ -n "$upgrade_cmd" ]]; then
                if [[ "$DRY_RUN" == "true" ]]; then
                    info_message "[DRY RUN] Would run: brew upgrade"
                else
                    start_spinner "Upgrading Homebrew packages..."
                    brew upgrade &> /dev/null || { stop_spinner_failure "Failed to upgrade Homebrew packages."; return 1; }
                    stop_spinner_success "Homebrew packages upgraded."
                fi
            fi
        ;;
        *) # Debian and RedHat
            if [[ -n "$update_cmd" ]]; then
                if [[ "$DRY_RUN" == "true" ]]; then
                    info_message "[DRY RUN] Would run: sudo $update_cmd"
                else
                    start_spinner "Updating package lists..."
                    echo "$SUDO_PASSWORD" | sudo -S $update_cmd &> /dev/null || { stop_spinner_failure "Failed to update package list."; return 1; }
                    stop_spinner_success "package lists updated."
                fi
            fi
            if [[ -n "$upgrade_cmd" ]]; then
                if [[ "$DRY_RUN" == "true" ]]; then
                    info_message "[DRY RUN] Would run: sudo $upgrade_cmd"
                else
                    start_spinner "Upgrading existing packages..."
                    echo "$SUDO_PASSWORD" | sudo -S $upgrade_cmd &> /dev/null || { stop_spinner_failure "Failed to upgrade existing packages."; return 1; }
                    stop_spinner_success "packages upgraded."
                fi
            fi
        ;;
    esac
}

ask_update_upgrade() {
    
    if ! get_yes_no_input "Do you want to update and upgrade system packages before installation?"; then
        info_message "Skipping system update and upgrade."
        return 0
    fi
    perform_update_upgrade
    return 0
}

install_package() {
    local package="$1"
    local dry_run="$2"
    
    info_message "\n[[Processing: $package]]\n"
    
    # Check if install script exists
    local script_path="./packages/$package.sh"
    if [[ ! -f "$script_path" ]]; then
        error_message "Installation script not found for $package at: $script_path"
        return 1
    fi
    
    # Get OS-specific install command
    local install_cmd=$(get_os_command "install" "$package")
    if [[ -z "$install_cmd" ]]; then
        warning_message "No installation command found for $package on this OS."
        # We might still want to execute the script for custom logic
        # return 1
    fi
    
    # Execute the installation script directly, passing the install command as an environment variable
    INSTALL_CMD="$install_cmd" bash "$script_path"
    local script_result="$?"
    if [[ "$script_result" -eq 0 ]]; then
        success_message "\n$package installed successfully.\n"
        return 0
    else
        error_message "\n$package installation failed (exit code: $script_result).\n"
        return 1
    fi
}

create_symlink() {
    local source_path="$1"
    local dest_path="$2"
    
    if [[ -L "$dest_path" ]]; then
        info_message "Symlink already exists: $dest_path"
        return 0
        elif [[ -e "$dest_path" ]]; then
        warning_message "Destination path exists but is not a symlink: $dest_path"
        return 1 # Or handle differently if needed
    fi
    
    if [[ "$DRY_RUN" == "true" ]]; then
        info_message "[DRY RUN] Would create symlink: $source_path -> $dest_path"
        return 0
    fi
    
    if ln -s "$source_path" "$dest_path"; then
        success_message "Created symlink: $source_path -> $dest_path"
        return 0
    else
        error_message "Failed to create symlink: $source_path -> $dest_path"
        return 1
    fi
}

check_and_install_dependencies() {
    # Array of dependencies to install
    local dependencies=("$@")
    
    for dep in "${dependencies[@]}"; do
        
        # Check if the dependency is already installed
        if command -v "$dep" &> /dev/null; then
            info_message "$dep is already installed. Skipping installation."
            continue # Go to the next dependency
        fi
        
        # Get OS-specific install command
        local install_cmd=$(get_os_command "install" "$dep")
        if [[ -z "$install_cmd" ]]; then
            warning_message "No installation command found for $dep on this OS."
            # We might still want to execute the script for custom logic
            # return 1
        fi
        
        # Check for sudo password (if needed)
        if ! get_sudo_password; then
            return 1 # Exit the function if sudo password retrieval fails
        fi
        
        echo "$install_cmd"
        # Install zsh (using sudo)
        start_spinner "$dep is not installed. Installing.."
        if [[ "$install_cmd" =~ ^(dnf|yum)\  ]]; then
            readarray -t cmd_array < <(echo "$install_cmd" | tr ' ' '\n')
            echo "$SUDO_PASSWORD" | sudo -S "${cmd_array[0]}" "${cmd_array[@]:1}" || { stop_spinner_failure "Failed to install $rep."; return 1; }
        else
            echo "$SUDO_PASSWORD" | sudo -S "$install_cmd" || { stop_spinner_failure "Failed to install $rep."; return 1; }
        fi
        stop_spinner_success "$dep installed successfully."
        
    done
    return 0
}