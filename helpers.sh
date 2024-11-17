#!/bin/bash

# Function to create a symlink, creating the target directory if necessary
function create_symlink() {
  local source="$1"
  local target="$2"
  local target_dir=$(dirname "$target")
  local target_filename=$(basename "$target")


  if [ -L "$target" ]; then
    echo -e "A symlink to \033[32m$target_filename\033[0m already exists. Overwrite it? (y/n)"
  else
    echo -e "Do you want to create a symlink to \033[32m$target_filename\033[0m? (y/n)"
  fi
  read -r answer
  if [[ "$answer" =~ ^[Yy]$ ]]; then
    mkdir -p "$(dirname "$target")"
    ln -sf "$source" "$target"
    echo -e "\033[32m$target_filename\033[0m config created/updated successfully."
  else
    echo -e "\033[32m$target_filename\033[0m config not created."
  fi
}

#Function to check or install a package in ubuntu or deb
function check_or_install_apt() {
  local package_name="$1"

  if command -v "$package_name" &> /dev/null; then
    echo -e "\033[32m$package_name\033[0m is installed. Proceeding..."
    return 0
  else
    echo "\033[32m$package_name\033[0m is not installed. Do you want to install it now? (y/n)"
    read -r answer

    if [[ "$answer" =~ ^[Yy]$ ]]; then
      sudo apt install "$package_name" -y
      echo "\033[32m$package_name\033[0m installed successfully."
      return 0
    else
      return 1
    fi
  fi
}

#function to check or install package using curl
function check_or_install_curl() {
  local url="$1"
  local package_name="$2"

  if command -v "$package_name" &> /dev/null; then
    echo "$package_name is already installed."
    return 0
  else
    echo "Do you want to install \033[32m$package_name\033[0m? (y/n)"
    read -r answer

    if [[ "$answer" =~ ^[Yy]$ ]]; then
      echo "Downloading and installing $package_name..."
      curl -sL "$url" | bash
      echo "$package_name installed successfully!"
      return 0
    else
      return 1
    fi
  fi
}
