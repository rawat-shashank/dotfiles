#!/bin/bash

# Source helpers for message functions
source "./modules/helpers.sh"

get_yes_no_input() {
    local prompt="$1"
    local choice
    
    # Check for -y flag
    if [[ "$ALL_YES" == "true" ]]; then
        return 0
    fi
    
    while true; do
        read -r -p "$prompt (y/N): " choice
        case "$choice" in
            y|Y)
                return 0
            ;;
            n|N)
                return 1
            ;;
            *)
                warning_message "Invalid input. Please enter y or n."
            ;;
        esac
    done
}