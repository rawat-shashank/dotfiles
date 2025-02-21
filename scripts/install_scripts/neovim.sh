#!/bin/bash

# neovim.sh - Installation script for Neovim (download, checksum, install)

# Include helper functions
source "$(dirname "$0")/../install_helpers.sh"

# Neovim version to check (adjust as needed)
NEOVIM_VERSION="0.10.4"

# Neovim Download URL (provided by you)
NEOVIM_URL="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz"
EXPECTED_CHECKSUM="95aaa8e89473f5421114f2787c13ae0ec6e11ebbd1a13a1bd6fcf63420f8073f"


# Check for curl and wget, install if necessary (curl preferred)
install_downloader() {
  if ! command -v curl &> /dev/null; then
    if ! command -v wget &> /dev/null; then
      warning_message "curl and wget not found. Installing curl..."
      if ! sudo apt install -y curl; then
        error_message "Failed to install curl.  Neovim installation cannot proceed."
        return 1
      fi
    fi
  fi
  return 0
}

install_neovim() {

  # Check if Neovim is already installed
  if command -v nvim &> /dev/null; then
    info_message "Neovim is already installed. Skipping download and installation."
    return 0 # Success (because it's already installed)
  fi

  if ! install_downloader; then
    return 1
  fi

  FILE_NAME=$(basename "$NEOVIM_URL")

  if [[ -f "$FILE_NAME" ]]; then
    info_message "Neovim archive file '$FILE_NAME' already exists. Skipping download."
  else
    # Download Neovim - use a spinner
    start_spinner "Downloading Neovim..."
    if command -v curl &> /dev/null; then
      DOWNLOAD_CMD="curl -L"
      DOWNLOAD_OPTIONS="-o"
    else
      DOWNLOAD_CMD="wget"
      DOWNLOAD_OPTIONS=""
    fi

    if ! $DOWNLOAD_CMD "$NEOVIM_URL" $DOWNLOAD_OPTIONS "$FILE_NAME"; then
      stop_spinner_failure "Failed to download Neovim."
      return 1
    fi
    stop_spinner_success "Neovim downloaded."
  fi

  # Verify Checksum (if available - you'll need to get the checksum from somewhere)
  start_spinner "Verifying Checksum..."
  ACTUAL_CHECKSUM=$(sha256sum "$FILE_NAME" | awk '{print $1}')

  if [[ "$ACTUAL_CHECKSUM" != "$EXPECTED_CHECKSUM" ]]; then
    stop_spinner_failure "Checksum verification failed!"
    rm "$FILE_NAME" # Remove the file since it's corrupted
    return 1
  fi
  stop_spinner_success "Checksum verified."

  # Extract Neovim - use a spinner
  start_spinner "Extracting Neovim..."
  ARCHIVE_NAME=$(basename "$FILE_NAME" .tar.gz)
  if ! tar xzvf "$FILE_NAME" > /dev/null; then
    stop_spinner_failure "Failed to extract Neovim."
    return 1
  fi
  stop_spinner_success "Neovim extracted."

  # Move Neovim to a user-specific bin directory
  USER_OPT_DIR="/opt"
  

  if [[ -d "$USER_OPT_DIR/$ARCHIVE_NAME" ]]; then # Check if the nvim directory exists
    info_message "Neovim directory already exists in $USER_OPT_DIR/$ARCHIVE_NAME. Skipping move."
  else
    # Check root status ONCE
    if ! get_sudo_password; then
      return 1
    fi
    start_spinner "Moving Neovim to user bin directory..."
    echo "$SUDO_PASSWORD" | sudo -S mkdir -p "$USER_OPT_DIR" || { stop_spinner_failure "Failed to create /opt directory."; return 1; }
    echo "$SUDO_PASSWORD" | sudo -S mv "$ARCHIVE_NAME" "$USER_OPT_DIR" || { stop_spinner_failure "Failed to move Neovim to /opt/."; return 1; }
    stop_spinner_success "Neovim moved to bin directory."
  fi

  # adding path to bashrc and zshrc
  # echo "export PATH=\"\$PATH:$USER_OPT_DIR/$ARCHIVE_NAME/bin\"" >> ~/.bashrc || { stop_spinner_failure "Failed to add Neovim to PATH (bash)."; return 1; }
  # echo "export PATH=\"\$PATH:$USER_OPT_DIR/$ARCHIVE_NAME/bin\"" >> ~/.zshrc || { stop_spinner_failure "Failed to add Neovim to PATH (zsh)."; return 1; }

  # sourcing to verify if it is installed properly
  source ~/.bashrc || { stop_spinner_failure "Failed to source ~/.bashrc."; return 1; }
  source ~/.zshrc || { stop_spinner_failure "Failed to source ~/.zshrc."; return 1; }

  # Verify Neovim installation and version
  nvim --version | grep "v${NEOVIM_VERSION}" > /dev/null 2>&1
  if [[ $? -eq 0 ]]; then
    success_message "Neovim $NEOVIM_VERSION installed and verified."
  else
    error_message "Neovim installation verification failed.  Version might be incorrect."
    return 1
  fi

  # Clean up (remove downloaded archive and extracted directory)
  rm "$FILE_NAME"
  rm -rf "$ARCHIVE_NAME"

  return 0
}

# Function to install dependencies (now handles an array)
install_dependencies() {
  local dependencies=("$@")  # Get all arguments as an array

  if [[ ${#dependencies[@]} -eq 0 ]]; then
    info_message "No dependencies specified. Skipping dependency installation."
    return 0
  fi

  for dependency in "${dependencies[@]}"; do
    if [[ "$DRY_RUN" == "true" ]]; then
      info_message "[DRY RUN] Would install dependency: $dependency"
      continue # Skip to the next dependency in dry run
    fi

    info_message "Installing dependency: $dependency..."

    # Check if the dependency is already installed (optional, but good practice)
    if command -v "$dependency" &> /dev/null; then # Check if command exists
      info_message "$dependency is already installed. Skipping."
      continue # Skip to the next dependency
    fi

    if ! get_sudo_password; then return 1; fi
    # Install the dependency using apt-get (or your preferred method)
    echo "$SUDO_PASSWORD" | sudo -S apt-get install -y "$dependency" || { error_message "Failed to install dependency: $dependency"; return 1; }

    success_message "Dependency $dependency installed successfully."
  done # End of the for loop
  return 0
}

install_neovim

# Install dependencies (after Neovim installation)
if [[ $? -eq 0 ]]; then # Only try to install dependencies if neovim install was successful
  declare -a neovim_deps=("xclip" "ripgrep") # Define the dependencies array
  install_dependencies "${neovim_deps[@]}" # Pass the array to the function

  #create symlink for nvim
  CONFIG_PATH=".config/nvim"
  create_symlink "$DOTFILE_PATH/$CONFIG_PATH" "$HOME/$CONFIG_PATH"
fi

