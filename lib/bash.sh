# lib/bash.sh

setup_bash_config() {
  log_info "Setting up modular Bash configuration from root bash directory..."

  local target_conf_dir="${CONFIG_HOME}/bash/conf.d"

  if [[ "${DRY_RUN}" == "true" ]]; then
    log_info "[DRY RUN] Would copy modules from ${BASH_DIR}/conf.d to ${target_conf_dir}"
    log_info "[DRY RUN] Would link ${BASH_DIR}/bashrc to ${HOME}/.bashrc"
    log_info "[DRY RUN] Would link ${BASH_DIR}/bash_profile to ${HOME}/.bash_profile"
    return 0
  fi

  # Ensure destination directory exists
  mkdir -p "${target_conf_dir}"

  # Copy modular scripts into ~/.config/bash/conf.d/
  if [[ -d "${BASH_DIR}/conf.d" ]]; then
    cp -r "${BASH_DIR}/conf.d/"*.bash "${target_conf_dir}/"
  fi

  # Link files as dotfiles in $HOME
  ln -sf "${BASH_DIR}/rc" "${HOME}/.bashrc"
  ln -sf "${BASH_DIR}/bash_profile" "${HOME}/.bash_profile"

  log_success "Bash configuration successfully deployed."
}
