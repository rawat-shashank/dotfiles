#!/bin/bash

# ----- Configuration -----
source ./helpers.sh

# ----- Items to Install/Configure -----
declare -a install_items=(
  "git"
  "zsh"
  #"oh-my-posh"
)

# ----- OS-Specific Commands (Ubuntu) -----
update_command="sudo apt upgrade & sudo apt update"
install_git_command="sudo apt install -y git"
install_zsh_command="sudo apt install -y zsh"
install_oh_my_posh_command="https://ohmyposh.dev/install.sh"
# ----- Main Script (Ubuntu Specific) -----

# Check for system updates
if [[ "$DRY_RUN" == "true" ]]; then
  info_message "Dry-run: Would execute: $update_command"
  stop_spinner_success "System updates check skipped (dry-run)."
else
  # Check if sudo password is required (non-blocking)
  if sudo -n true; then
    # Sudo doesn't require password

    # Prompt user FIRST
    read -p "Press Enter to proceed with system update and upgrade..."

    # NOW start the spinner
    start_spinner "Updating and Upgrading system..."

    if eval "$update_command"; then
      stop_spinner_success "System updated and upgraded."
    else
      stop_spinner_failure "System update and upgrade failed."
    fi
  else
    # Sudo requires password
    if tty -s; then
      # Interactive shell

      # Prompt user FIRST
      read -p "Press Enter to proceed with system update and upgrade (may require password)..."

      # NOW start the spinner
      start_spinner "Updating and Upgrading system..."

      if eval "$update_command"; then  # User will be prompted for password here
        stop_spinner_success "System updated and upgraded."
      else
        stop_spinner_failure "System update and upgrade failed after password prompt."
      fi
    else
      warning_message "Non-interactive shell, skipping system updates requiring password."
      stop_spinner_skipped "System updates skipped (non-interactive and password needed)."
    fi
  fi
fi

# check and install zsh
install_zsh_and_config() {
  local install_zsh_command="$1"
  package_name="zsh"

  if check_or_install_package "$package_name" "$install_zsh_command"; then
    if [[ "$SHELL" == "/bin/zsh" ]]; then
      info_message "Your default shell is Zsh. Proceeding..."
    else
      read -r -p "Your default shell is not Zsh. Would you like to set it to Zsh? (y/n): " answer

      if [[ "$answer" =~ ^[Yy]$ ]]; then
        if [[ "$DRY_RUN" == "true" ]]; then
          info_message "Dry-run: Would execute chsh -s /bin/zsh"
          info_message "Dry-run: Please log out and log back in for the change to take effect."
        else
          chsh -s /bin/zsh
          success_message "Default shell changed to Zsh. Please log out and log back in for the change to take effect."
        fi
      fi
    fi

    info_message "linking .zshrc config"
    current_path=$(dirname "$0") # Get script directory
    source_file="$current_path/.zshrc"
    target_file="$HOME/.zshrc"
    create_symlink "$source_file" "$target_file"
    return 0 # Zsh and config processed
  else
    error_message "Failed to install $package_name. Zsh config setup aborted."
    return 1 # Zsh install failed
  fi
}

# -----  install_oh_my_posh_and_config function (in ubuntu.sh) -----
install_oh_my_posh_and_config() {
  package_url="https://ohmyposh.dev/install.sh"
  package_name="oh-my-posh"
  if check_or_install_curl "$package_url" "$package_name"; then # Reuses check_or_install_curl from helpers
    info_message "linking ohmyposh config"
    current_path=$(dirname "$0") # Get script directory
    ohmyposh_source_file="$current_path/.config/ohmyposh/zen.toml"
    ohmyposh_target_file="$HOME/.config/ohmyposh/zen.toml"
    create_symlink "$ohmyposh_source_file" "$ohmyposh_target_file"

    if [[ "$DRY_RUN" == "true" ]]; then
      info_message "Dry-run: Would append to ~/.zshrc.general:"
      info_message "Dry-run: eval \"\$(oh-my-posh init zsh --config \$HOME/.config/ohmyposh/zen.toml)\""
    else
      echo "eval \"\$(oh-my-posh init zsh --config \$HOME/.config/ohmyposh/zen.toml)\"" >>~/.zshrc.general
    fi
    return 0 # oh-my-posh and config processed
  else
    error_message "Failed to install $package_name. oh-my-posh config setup aborted."
    return 1 # oh-my-posh install failed
  fi
}
# Install items from the list
for item in "${install_items[@]}"; do
  case "$item" in
  "git")
    start_spinner "Checking and installing Git..."
    if check_or_install_package "git" "$install_git_command"; then
      stop_spinner_success "Git installation/check complete."
    else
      stop_spinner_failure "Git installation/check failed."
    fi
    ;;
  "zsh")
    start_spinner "Checking and installing Zsh and Zsh config..."
    if install_zsh_and_config "$install_zsh_command"; then
      stop_spinner_success "Zsh and Zsh config installation/check complete."
    else
      stop_spinner_failure "Zsh and Zsh config installation/check failed."
    fi
    ;;
  "oh-my-posh")
    start_spinner "Checking and installing oh-my-posh and config..."
    if install_oh_my_posh_and_config; then
      stop_spinner_success "oh-my-posh and config installation/check complete."
    else
      stop_spinner_failure "oh-my-posh and config installation/check failed."
    fi
    ;;
  *)
    warning_message "Unknown item in install list: $item"
    ;;
  esac
done

success_message "Ubuntu setup script completed."
