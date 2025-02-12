#!/bin/bash

# ----- Configuration -----
source ./helpers.sh # Source helper functions

# ----- Configuration -----
export DRY_RUN=true

# --- Option Parsing ---
while [[ $# -gt 0 ]]; do
  case "$1" in
  -x | --execute)
    DRY_RUN=false # Set dry-run to FALSE if -x or --execute flag is given
    shift
    ;;
  *)
    break # Stop option parsing, treat remaining args as non-options
    ;;
  esac
done

# ----- OS Detection -----
detect_os() {
  if [[ -n "$WSL_DISTRO_NAME" ]]; then
    OS="ubuntu" # Assuming WSL is Ubuntu in this example
  elif [[ "$OSTYPE" == "linux-gnu" ]]; then
    OS="ubuntu" # Assuming Ubuntu or Debian-based for linux-gnu in this example
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
  else
    OS="unknown"
  fi
  echo "$OS"
}

OS=$(detect_os)

# ----- Call OS-Specific Script -----
case "$OS" in
"ubuntu")
  bash ubuntu.sh # Call ubuntu.sh for Ubuntu-based systems
  ;;
"macos")
  # For future macOS support, you would call macos.sh or similar
  # bash macos.sh
  error_message "macOS setup is not yet implemented."
  exit 1
  ;;
"unknown")
  error_message "Unknown OS detected: $OS. Aborting."
  exit 1
  ;;
esac

success_message "installation setup completed."
