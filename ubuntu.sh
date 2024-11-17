# !/bin/bash

##check for any updates first
echo "Checking for updates..."
# sudo apt update

# current working directory for symlinks
current_path=$(pwd)
source ./helpers.sh

#check or install git
check_or_install_apt "git"

#check or install zsh and zsh configs
if check_or_install_apt "zsh"; then
  if [[ "$SHELL" == "/bin/zsh" ]]; then
    echo "Your default shell is Zsh. Proceeding..."
  else
    echo "Your default shell is not Zsh. Would you like to set it to Zsh? (y/n)"
    read -r answer

    if [[ "$answer" =~ ^[Yy]$ ]]; then
      chsh -s /bin/zsh
      echo "Default shell changed to Zsh. Please log out and log back in for the change to take effect."
    fi
  fi

  echo "linking .zshrc config"
  source_file="$current_path/.zshrc"
  target_file="$HOME/.zshrc"
  create_symlink "$source_file" "$target_file"

fi

#check or install oh-my-posh and my zen.toml config
package_url="https://ohmyposh.dev/install.sh"
package_name="oh-my-posh"
if check_or_install_curl  "$package_url" "$package_name"; then
  echo "linking ohmyposh config"
  ohmyposh_source_file="$current_path/.config/ohmyposh/zen.toml"
  ohmyposh_target_file="$HOME/.config/ohmyposh/zen.toml"
  create_symlink "$ohmyposh_source_file" "$ohmyposh_target_file"
  echo "here"
  echo "eval \"\$(oh-my-posh init zsh --config $HOME/.config/ohmyposh/zen.toml)\"" >> ~/.zshrc.general
fi
