#!/bin/bash

# ----- Color Functions -----
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

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

# ----- Internal Helper Function (for code reuse) -----
_perform_package_installation() {
  local package_name="$1"
  local install_execution="$2" # Code snippet to execute installation

  info_message "Checking and installing $package_name..."
  if command -v "$package_name" &> /dev/null; then
    info_message "$package_name is already installed."
    return 0
  else
    info_message "$package_name is not installed. Installing..."
    if [[ "$DRY_RUN" == "true" ]]; then
      # Capture the command to be executed for dry-run output
      info_message "Dry-run: Would execute: $install_execution"
      return 1 # Simulate not installed for dry-run
    else
      # Execute the provided installation code snippet
      eval "$install_execution"

      if command -v "$package_name" &> /dev/null; then
        success_message "$package_name installed successfully."
        return 0
      else
        error_message "Failed to install $package_name."
        return 1
      fi
    fi
  fi
}

# Function to create a symlink, creating the target directory if necessary
create_symlink() {
  local source_file="$1"
  local target_file="$2"

  if [[ -L "$target_file" ]]; then
    info_message "Symlink already exists at $target_file"
  else
    info_message "Creating symlink from $source_file to $target_file..."
    if [[ "$DRY_RUN" == "true" ]]; then
      info_message "Dry-run: Would create symlink from $source_file to $target_file"
    else
      mkdir -p "$(dirname "$target_file")"
      ln -sf "$source_file" "$target_file"
      if [[ -L "$target_file" ]]; then
        success_message "Symlink created successfully at $target_file"
      else
        error_message "Failed to create symlink at $target_file"
      fi
    fi
  fi
}

#Function to check or install a package - OS-agnostic check, installation command to be provided by caller
check_or_install_package() {
  local package_name="$1"
  local install_command="$2"

  _perform_package_installation "$package_name" "$install_command"
}

#function to check or install package using curl
check_or_install_curl() {
  local package_url="$1"
  local package_name="$2"

  # Directly call internal function with curl-specific execution
  _perform_package_installation "$package_name" "bash <(curl -s \"\$package_url\")"
}
