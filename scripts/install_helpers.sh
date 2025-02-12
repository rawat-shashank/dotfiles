#!/bin/bash

# ----- Color Functions -----
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'

# ----- Messages Functions -----
success_message() {
  echo -e "${GREEN}Success: $1${NC}"
}

warning_message() {
  echo -e "${YELLOW}Warning: $1${NC}"
}

error_message() {
  echo -e "${RED}Error: $1${NC}"
}

info_message() {
  echo -e "$1" # Info messages are not colored by default, can be extended
}

# ----- spinner Functions -----
start_spinner() {
  SPINNER_CHARS="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
  SPINNER_PID=0
  MESSAGE="$1"

  spinner_func() {
    local i=0
    while true; do
      printf "\r${YELLOW}${SPINNER_CHARS:$i:1}${NC} $MESSAGE"
      i=$(((i + 1) % ${#SPINNER_CHARS}))
      sleep 0.1
    done
  }

  spinner_func &
  SPINNER_PID=$!
}

stop_spinner_success() {
  if [[ -n "$SPINNER_PID" ]]; then
    kill "$SPINNER_PID" 2>/dev/null
    printf "\r${GREEN}✔${NC} $1\n"
    SPINNER_PID=0
  fi
}

stop_spinner_failure() {
  if [[ -n "$SPINNER_PID" ]]; then
    kill "$SPINNER_PID" 2>/dev/null
    printf "\r${RED}✘${NC} $1\n"
    SPINNER_PID=0
  fi
}

# ----- Helper Functions -----
# Function to install a package (modified to NOT use spinners yet)
install_package() {
  local package="$1"
  local install_dir="$2"
  local dry_run="$3"

  echo "Processing: $package"

  # Check if install script exists
  local script_path="$install_dir/$package.sh"
  if [[ ! -f "$script_path" ]]; then
    error_message "Installation script not found for $package"
    return 1
  fi

  # Dry-run mode
  if [[ "$dry_run" == "true" ]]; then
    info_message "Dry-run: Would execute $script_path"
    return 0
  fi

  # Execute the installation script directly (no spinner)
  if bash "$script_path"; then
    success_message "$package installed successfully."
    return 0
  else
    error_message "$package installation failed."
    return 1
  fi
}

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

create_symlink() {
  local source_path="$1"  # Path to the source file or directory
  local target_path="$2"  # Path to the target location

  # Check if the source path exists
  if [[ ! -e "$source_path" ]]; then # -e checks for file or directory
    error_message "Source path '$source_path' not found."
    return 1
  fi

  # Extract source directory and name
  local source_dir=$(dirname "$source_path")
  local source_name=$(basename "$source_path")

  # Extract target directory and name
  local target_dir=$(dirname "$target_path")
  local target_name=$(basename "$target_path")

  # Check if the target directory exists (create it if it doesn't)
  if [[ ! -d "$target_dir" ]]; then
    mkdir -p "$target_dir" || { error_message "Failed to create target directory '$target_dir'."; return 1; }
  fi

  # Check if a symlink already exists at the target location
  if [[ -L "$target_path" ]]; then # -L checks for symlink
    # If the existing symlink points to the correct location, do nothing
    if [[ "$(readlink "$target_path")" == "$source_path" ]]; then
      info_message "Symlink already exists and points to the correct location. Skipping."
      return 0
    else
      # If the symlink exists but points to wrong place, ask if to overwrite
      read -p "A symlink already exists at $target_path pointing to $(readlink "$target_path"). Do you want to overwrite it? (y/N) " choice
      case "$choice" in
        y|Y)
          rm "$target_path" || { error_message "Failed to remove the existing symlink."; return 1; }
          ;;
        *)
          info_message "Skipping symlink creation."
          return 0
          ;;
      esac
    fi
  elif [[ -e "$target_path" ]]; then # -e checks for any file or directory
    read -p "A file or directory already exists at $target_path. Do you want to overwrite it with symlink? (y/N) " choice
    case "$choice" in
      y|Y)
        rm -rf "$target_path" || { error_message "Failed to remove the existing file or directory."; return 1; }
        ;;
      *)
        info_message "Skipping symlink creation."
        return 0
        ;;
    esac
  fi

  # Create the symlink
  ln -s "$source_path" "$target_path" || { error_message "Failed to create symlink."; return 1; }

  success_message "Symlink created successfully."
  return 0
}
