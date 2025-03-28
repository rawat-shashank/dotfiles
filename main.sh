#!/bin/bash

# Source constants
source "./modules/env.sh"

# Source help command functions
source "./modules/help.sh"

# Source helper functions
source "./modules/helpers.sh"

# # Source system-related functions
source "./modules/system.sh"

# --- Process Command-Line Arguments (Help, Dry-run and Yes-to-all) ---
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --help | -h)
            show_help
            exit 0
        ;;
        --dry-run)
            DRY_RUN="true"
            shift
        ;;
        -y)
            ALL_YES="true"
            shift
        ;;
        *)
            break  # Stop processing flags for dry-run and yes
        ;;
    esac
done

# Reset positional parameters for the next loop
shift $((OPTIND-1))

# --- Main Execution ---

# Ask for initial update and upgrade BEFORE package installations
info_message "\n[[System update and upgrade]]]\n"
ask_update_upgrade

for package in "${packages[@]}"; do
    if ! get_yes_no_input "Do you want to install $package?"; then
        info_message "Skipping $package installation."
        continue  # Skip to the next package
    fi
    install_package "$package" "$DRY_RUN"
done

echo "Installation process complete."